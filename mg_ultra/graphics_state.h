/*The interface between gamestate and GLHandler,
Doesnt actually do much gl tho*/
#ifndef __GRAPHICS_STATE__
#define __GRAPHICS_STATE__

#include <mutex>

#include "shaders.h"
#include "constants.h"
#include "gl_handler.h"

class GraphicsState {
private:
	// Graphics settings
	GraphicsSettings* gSettings = new GraphicsSettings();

	// Handles GL calls and interaction with the gl interface
	GLHandler* glHandler = nullptr;

	// Camera object
	Camera* camera = nullptr;

	// Texture master
	AnimationsMaster* animationsMaster = nullptr;
	
	// Creates window returns EXIT_FAILURE on fail, else EXIT_SUCCESS
	int createWindowAndPassToGLHandler() {
		// Initialise GLFW
		if (!glfwInit()) {
			//TODO fprintf(stderr, "Failed to initialize GLFW\n");
			return EXIT_FAILURE;
		}

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

		// Open a window and create its OpenGL context
		GLFWmonitor* monitor = gSettings->fullScreen ? glfwGetPrimaryMonitor() : nullptr;
		if (monitor) {
			const GLFWvidmode* mode = glfwGetVideoMode(monitor);
			glfwWindowHint(GLFW_RED_BITS, mode->redBits);
			glfwWindowHint(GLFW_GREEN_BITS, mode->greenBits);
			glfwWindowHint(GLFW_BLUE_BITS, mode->blueBits);
			glfwWindowHint(GLFW_REFRESH_RATE, mode->refreshRate);
		}

		GLFWwindow *window = glfwCreateWindow(gSettings->screenWidth, gSettings->screenHeight, "mg_ultra", monitor, nullptr);
		if (window == NULL) {
			glfwTerminate();
			return EXIT_FAILURE;
		}

		glViewport(0, 0, gSettings->screenWidth, gSettings->screenHeight);

		// Make context current for a bit on initialise thread
		glfwMakeContextCurrent(window);
		glewExperimental = true;
		if (glewInit() != GLEW_OK) {
			fprintf(stderr, "Failed to initialize GLEW\n");
			return EXIT_FAILURE;
		}

		// Create camera
		camera = new Camera(gSettings);
		
		// Create texture master
		animationsMaster = new AnimationsMaster();

		// Switch over to the GLHandler
		glHandler = new GLHandler(window, gSettings, animationsMaster, camera);

		return EXIT_SUCCESS;
	}

public:
	// Creates graphic states and initialises openGL
	GraphicsState() {
		//create a window and pass it off to GLHander
		if FAILURE(createWindowAndPassToGLHandler()) {
			//TODO
		}
	}

	Camera* getCamera() {
		return camera;
	}

	~GraphicsState() {
		delete glHandler;
		delete camera;
		delete gSettings;
	}

	GLFWwindow* getWindow() {
		return glHandler->getWindow();
	}

	AnimationsMaster* getAnimationsMaster() {
		return animationsMaster;
	}

	//initialises the GLHandler into calling thread
	void initialiseCallingThread() {
		glHandler->glThreadInitialise(getWindow(), gSettings);
	}

	// Gets the GLHandler to render
	void renderGL() {
		glHandler->render();
	}

	BoxData evaluateToBox(AnimationState state, float scale) {
		return animationsMaster->evaluateToBox(state, scale);
	}

	///BoxDataBuffer

	// Gets a pointer to a buffered map
	BoxData* getBoxDataBuffer() {
		return glHandler->getBoxDataBuffer().getWriteBuffer();
	}

	// Commit the directionalLightVAOBuffer buffer
	void commitBoxDataBuffer(int boxCount) {
		glHandler->getBoxDataBuffer().commitBuffer(boxCount);
	}

	// Returns the size of the GLHandler's boxBufferDataBuffer size
	int getBoxDataBufferSize() {
		return glHandler->getBoxDataBuffer().getMaxSize();
	}

	///UI BoxData

	// Gets a pointer to a buffered map
	BoxData* getUIBoxDataBuffer() {
		return glHandler->getUIBoxDataBuffer().getWriteBuffer();
	}

	// Commit the directionalLightVAOBuffer buffer
	void commitUIBoxDataBuffer(int boxCount) {
		glHandler->getUIBoxDataBuffer().commitBuffer(boxCount);
	}

	// Returns the size of the GLHandler's boxBufferDataBuffer size
	int getUIBoxDataBufferSize() {
		return glHandler->getUIBoxDataBuffer().getMaxSize();
	}

	///DirectionalDataBuffer

	// Gets a pointer to a buffered map
	DirectionalData* getDirectionDataBuffer() {
		return glHandler->getDirectionalLightBuffer().getWriteBuffer();
	}

	// Commit the directionalLightVAOBuffer buffer
	void commitDirectionalDataBuffer(int directionCount) {
		glHandler->getDirectionalLightBuffer().commitBuffer(directionCount);
	}

	// Returns the size of the GLHandler's directionalLightVAOBuffer size
	int getDirectionalDataBufferSize() {
		return glHandler->getDirectionalLightBuffer().getMaxSize();
	}

	///PointLightDataBuffer
	// Gets a pointer to a buffered map
	PointLightData* getPointLightDataBuffer() {
		return glHandler->getPointLightBuffer().getWriteBuffer();
	}

	// Commit the directionalLightVAOBuffer buffer
	void commitPointLightDataBuffer(int directionCount) {
		glHandler->getPointLightBuffer().commitBuffer(directionCount);
	}

	// Returns the size of the GLHandler's directionalLightVAOBuffer size
	int getPointLightDataBufferSize() {
		return glHandler->getPointLightBuffer().getMaxSize();
	}
};


#endif // ifndef GRAPHICS_STATE