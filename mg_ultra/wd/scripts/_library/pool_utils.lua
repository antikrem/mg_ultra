--Adds utilities to interact with the pool

--global pool, contains all the entities in the game
pool = getEntityPool()

---Enumeration of different types of entities
--
EntityNoType = 0
EntityGeneric = 1
EntityGameControl = 2
EntityConsole = 3
EntityCamera = 4
EntityPlayer = 5

--returns the entity cached with this types
--or nil on failure due to invalid type or no respective cached ent
function EntityPool.get_cached_entity(entityType)
	return pool:getEntFromCache(entityType)
end

function EntityPool.get_entity_count()
	return pool:size()
end

--gets the number of entities in the graveyard
function EntityPool.get_graveyard_size() 
	return pool:getGraveyardSize()
end

--gets the number of entities passed by the pool
function EntityPool.get_graveyard_passed() 
	return pool:getGraveyardPassed()
end