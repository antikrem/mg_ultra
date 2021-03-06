/*Manages all audio rescources
*/
#ifndef __AUDIO_MASTER__
#define __AUDIO_MASTER__

#include <map>
#include <vector>
#include <tuple>
#include <condition_variable>

#include "error.h"

#include "audio_file.h"
#include "audio_source.h"

class AudioMaster {
	ALCdevice* device;
	ALCcontext* context;

	map<string, AudioFile*> audioFiles;

	mutex sourceDispositionLock;
	vector<ALuint> sourcesToDispose;

	mutex assetsLock;
	vector<tuple<string, string, AudioFileLifecycle>> requestedLoads;
	condition_variable assetsQueueCondition;

	// When loading assets, looks at this directory for sources
	string location = "/sounds/";

	int queuedAssetsCounts() {
		return (int)requestedLoads.size();
	}

public:
	// Creates a new audio file from given source
	// If not possible, returns false and makes no change
	bool createAudioFile(const string& name, const string& location, AudioFileLifecycle lifeCycle) {
		if (audioFiles.count(name)) {
			return false;
		}

		audioFiles[name] = new AudioFile(lifeCycle);

		if (!audioFiles[name]->loadAudioFile(location)) {
			delete audioFiles[name];
			audioFiles.erase(name);
			return false;
		}
		
		return true;
	}

	AudioMaster() {
		err::logMessage("AUDIO: Initialising audio subsystem");

		const char* deviceName = alcGetString(NULL, ALC_ALL_DEVICES_SPECIFIER);

		device = alcOpenDevice(deviceName);
		context = alcCreateContext(device, NULL);
		alcMakeContextCurrent(context);

		err::logMessage("AUDIO: Audio subsystem initialised");
		err::logMessage("AUDIO: Utilising device: " + string(deviceName));

		alGetError();
	}

	~AudioMaster() {
		g_audio::closeAudioPipeLine();
		alcMakeContextCurrent(NULL);
		alcDestroyContext(context); 
		alcCloseDevice(device);
	}

	map<string, AudioFile*>& getAudioFiles() {
		return audioFiles;
	}

	// Adds a buffer to be disposed
	void disposeSource(ALuint buffer) {
		unique_lock<mutex> lck(sourceDispositionLock);
		sourcesToDispose.push_back(buffer);
	}



	// Queues a audio file to be added
	void queueAssetLoad(const string& audioName, const string& audioLocation, AudioFileLifecycle lifeCycle) {
		unique_lock<mutex> lck(assetsLock);
		requestedLoads.push_back(make_tuple(audioName, audioLocation, lifeCycle));
	}

	// Flushes all queued assets
	void flushAssetLoadRequests() {
		unique_lock<mutex> lck(assetsLock);
		assetsQueueCondition.wait(
			lck,
			[this]() {
				return !this->queuedAssetsCounts();
			}
		);
	}

	void updateMaster() {
		{
			unique_lock<mutex> lck(sourceDispositionLock);
			alDeleteSources(sourcesToDispose.size(), sourcesToDispose.data());
			sourcesToDispose.clear();
		}
		{
			unique_lock<mutex> lck(assetsLock);
			for (auto i : requestedLoads) {
				if (!createAudioFile(
					get<0>(i),
					get<1>(i),
					get<2>(i)
				)) {
					err::logMessage("AUDIO: Error, failed to load asset: " + get<0>(i) + " @ " + get<1>(i));
				}
			}
			requestedLoads.clear();
			assetsQueueCondition.notify_all();
		}
	}

	// Takes ownership of context into this thread
	void reclaimContext() {
		alcMakeContextCurrent(context);
	}

	// Returns the last error of audio
	ALenum getLastError() {
		return alGetError();
	}

	// Prints a report
	void printReport() {
		err::logMessage("AUDIO: generating report:");
		unique_lock<mutex> lck(assetsLock);
		for (auto& i : audioFiles) {
			err::logMessage("File: " + i.first + " @ " + i.second->getFileLocation());
		}
		err::logMessage("AUDIO: End of report");
	}

};

namespace g_audio {
	// Sets global audio master
	void setAudioMaster(AudioMaster* audioMaster);

	// Sets next load context
	void setLoadContext(const string& location, int lifeCycle);

	// Adds an audio to the audio master when AL is next updated
	void addAudioFile(const string& fileName, const string& fileLocation);

	// Flushes all audio load requests
	void flushAudioLoadRequests();

	// Prints a small audio report
	void print();
}

#endif