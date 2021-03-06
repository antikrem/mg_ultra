#include "audio_master.h"

#include <shared_mutex>

shared_mutex audioPtrLock;
AudioMaster* globalAudioMaster = nullptr;
bool activePipeline = false;

// Default to global
string loadcontext = "sounds\\";
AudioFileLifecycle contextLifecycle = AuFiLi_Global;

void g_audio::setAudioMaster(AudioMaster* audioMaster) {
	unique_lock<shared_mutex> lck(audioPtrLock);
	globalAudioMaster = audioMaster;
	activePipeline = true;
}

void g_audio::closeAudioPipeLine() {
	unique_lock<shared_mutex> lck(audioPtrLock);
	activePipeline = false;
	globalAudioMaster = nullptr;
}

void g_audio::disposeSource(ALint buffer) {
	shared_lock<shared_mutex> lck(audioPtrLock);
	if (activePipeline) {
		globalAudioMaster->disposeSource(buffer);
	}
	
}

void g_audio::setLoadContext(const string& location, int lifeCycle) {
	unique_lock<shared_mutex> lck(audioPtrLock);
	loadcontext = location;
	contextLifecycle = (AudioFileLifecycle)lifeCycle;
}

void g_audio::addAudioFile(const string& fileName, const string& fileLocation) {
	shared_lock<shared_mutex> lck(audioPtrLock);
	if (activePipeline) {
		globalAudioMaster->queueAssetLoad(fileName, loadcontext + fileLocation, contextLifecycle);
	}
}

void g_audio::flushAudioLoadRequests() {
	shared_lock<shared_mutex> lck(audioPtrLock);
	if (activePipeline) {
		globalAudioMaster->flushAssetLoadRequests();
	}
}

void g_audio::print() {
	shared_lock<shared_mutex> lck(audioPtrLock);
	if (activePipeline) {
		globalAudioMaster->printReport();
	}
}