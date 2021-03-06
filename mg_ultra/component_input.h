/*Allows last input to be exposed to lua environment
update is not async to lua query*/
#ifndef __COMPONENT_INPUT__
#define __COMPONENT_INPUT__

#include "component.h"
#include "scriptable_class.h"
#include "script_master.h"
#include "input.h"

class ComponentInput : public Component, public ScriptableClass<ComponentInput> {
	InputState inputState;

public:
	ComponentInput() {
		input::getCurrentInputMaster()->seedState(&inputState);
		update();
	}

	void update() {
		input::getCurrentInputMaster()->updateState(&inputState);
	}

private:
	int queryPress(string keyName) {
		if (inputState.pressEvent.count(keyName)) {
			return inputState.pressEvent[keyName];
		}
		return -1;
	}

	int queryDown(string keyName) {
		if (inputState.press.count(keyName)) {
			return inputState.press[keyName];
		}
		return -1;
	}

public:
	static void registerToLua(kaguya::State& state) {
		state["ComponentInput"].setClass(kaguya::UserdataMetatable<ComponentInput, Component>()
			.setConstructors<ComponentInput()>()
			.addFunction("update", &ComponentInput::update)
			.addFunction("query_press", &ComponentInput::queryPress)
			.addFunction("query_down", &ComponentInput::queryDown)
			.addOverloadedFunctions(
				"create",
				ScriptableClass::create<ComponentInput>
			)
			.addStaticFunction("type", &getType<ComponentInput>)
			.addStaticFunction("cast", &Component::castDown<ComponentInput>)
		);
	}
};

#endif