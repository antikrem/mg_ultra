/*A container for entities used with entities,
Can be iterated over safely*/
#ifndef __POOL__
#define __POOL__

#include <mutex>
#include <vector>
#include <map>
#include <shared_mutex>
#include <cassert>
#include "constants.h"
#include "entity.h"

/*This can be asyncly iterated over,
Use begin() to get an id int,
Use this id and next() to get next pair
After the last pair, return negative id, not guranteed: null ptr*/
class EntityPool {
private:
	//Locks during access
	shared_mutex lock;
	//Entities are mapped to ids
	map<int, shared_ptr<Entity>> list;
	//A seperate cache, int refers to the entity type
	//Entities will be in both cache and list. Both are cleared by clearDeadEnts
	map<int, shared_ptr<Entity>> cache;
	//Largest id used
	int largestID = -1;

	//lock for graveyard
	mutex graveyardLock;
	//graveyard
	vector<shared_ptr<Entity>> graveyard;

public:
	EntityPool();

	int begin() {
		shared_lock<shared_mutex> lck(lock);
		if not(list.size()) {
			return -1;
		}
		return list.begin()->first;
	}
	
	int next(int id) {
		shared_lock<shared_mutex> lck(lock);
		if (id >= largestID) {
			return -1;
		}

		//get an interator to the current element
		auto it = list.find(id);

		if (it == list.end() || (++it) == list.end()) {
			return -1;
		}
		
		return it->first;
	}

	//adds a new entity, in a thread safe way
	//set cacheEnt to true to add the cache 
	//returns false if attempted to cache but an ent of the same type already exists
	bool addEnt(Entity* ent, bool cacheEnt = false) {
		return addEnt(shared_ptr<Entity>(ent), cacheEnt);
	}

	//alternative method to addEnt to add a shared ptr
	bool addEnt(shared_ptr<Entity> ent, bool cacheEnt = false) {
		unique_lock<shared_mutex> lck(lock);
		largestID++;
		list[largestID] = ent;
		if (cacheEnt) {
			if (cache.count(ent->getType())) {
				return false;
			}
			cache[ent->getType()] = list[largestID];
		}
		return true;
	}

	//On failure, returns null, may fail with a valid id, as that id could have be deleted
	shared_ptr<Entity> getEnt(int id) {
		shared_lock<shared_mutex> lck(lock);
		if (list.count(id)) {
			return list[id];
		}
		else {
			return nullptr;
		}
	}

	//returns a system from cache, returns null if the system is not cached
	shared_ptr<Entity> getCachedEnt(int entityType) {
		//use null type 
		if not(entityType) {
			return nullptr;
		}
		shared_lock<shared_mutex> lck(lock);
		if (cache.count(entityType)) {
			return cache[entityType];
		}
		else {
			return nullptr;
		}
	}

	//clear dead entities, needs to be sometimes, locks access to ents, so should only be done sometimes
	//returns how many ents were killed
	int clearDeadEnts() {
		int cleanedEnts = 0;
		unique_lock<shared_mutex> lck(lock);

		for (auto i : list) {
			i.second->entityUpdate();
		}
		
		{
			//clear list
			auto it = list.begin();
			while (it != list.end()) {
				if (it->second->getFlag()) {
					it++;
				}
				else {
					unique_lock<mutex> glck(graveyardLock);
					graveyard.push_back(it->second);
					it = list.erase(it);
				}
			}
		}

		{
			//clear cache
			auto it = cache.begin();
			while (it != cache.end()) {
				if (it->second->getFlag()) {
					it++;
				}
				else {
					it = cache.erase(it);
				}
			}
		}

		return cleanedEnts;
	}

	//locks and returns size of entitypool
	tuple<int, int> size() {
		unique_lock<shared_mutex> lck(lock);
		return make_tuple(list.size(), cache.size());
	}

	//returns size of graveyard
	int getGraveYardSize() {
		unique_lock<mutex> lck(graveyardLock);
		return graveyard.size();
	}
};

EntityPool* getLastPool();

#endif