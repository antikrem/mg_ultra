/*Camera is handled by a script 300 times a second
the script loaded is in script/camera.lua
*/
#ifndef __COMPONENT_CAMERA__
#define __COMPONENT_CAMERA__

#include "component.h"
#include "cus_struct2.h"
#include "script_master.h"
#include "scriptable_class.h"

//different modes for camera
enum CameraMode {
	CM_track,
	CM_direction
};

class ComponentCamera : public Component, public ScriptableClass {
	//current mdoe of the camera
	atomic<CameraMode> cameraMode = CM_direction;
	//treats location as a vector
	atomic<Point3> viewTarget;

public:

	ComponentCamera() : viewTarget{ Point3(0,0,0) } {
	}
	
	glm::vec3 getViewTarget(Point3 cameraPos) {
		return viewTarget.load().getVec3();
	}

	void setCameraTarget(Point3 target) {
		viewTarget = target;
	}

	void setCameraMode(int mode) {
		cameraMode = (CameraMode)mode;
	}

	tuple<float, float, float> l_getViewTarget() {
		return tuple<float, float, float>(viewTarget.load().x, viewTarget.load().y, viewTarget.load().z);
	}

	void l_setViewTarget(float x, float y, float z) {
		viewTarget = Point3(x, y, z);
	}

	void l_addViewTarget(float x, float y, float z) {
		viewTarget = viewTarget.load() + Point3(x, y, z);
	}

	void registerToLua(kaguya::State& state) override {
		state["ComponentCamera"].setClass(kaguya::UserdataMetatable<ComponentCamera, Component>()
			.setConstructors<ComponentCamera()>()
			.addFunction("get_view_target", &ComponentCamera::l_getViewTarget)
			.addStaticFunction("type", &getType<ComponentCamera>)
			.addStaticFunction("cast", &Component::castDown<ComponentCamera>)
		);
	}

};


#endif