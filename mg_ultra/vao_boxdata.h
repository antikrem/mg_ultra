/**
 * Implementation of vao_buffer for
 * BoxData
 */

#ifndef __VAO_BOXDATA__
#define __VAO_BOXDATA__

#include "vao_buffer.h"

const float BASEQUAD[12] = {
	-0.5f, -0.5f, 0.0f,
	-0.5f, 0.5f, 0.0f,
	0.5f, -0.5f, 0.0f,
	0.5f, 0.5f, 0.0f
};

class VAOBoxData : public VAOBuffer<VAOBoxData, BoxData> {

	// Quad index, index corresponds to VAO
	GLuint quadID = 0;

public:
	void setUpAttribPointers() {
		// Generate and bind base quad buffer
		glGenBuffers(1, &quadID);
		glBindBuffer(GL_ARRAY_BUFFER, quadID);
		glBufferData(GL_ARRAY_BUFFER, sizeof(BASEQUAD), BASEQUAD, GL_STATIC_DRAW);

		// Generate and bind instance buffer
		glGenBuffers(1, &vboID );
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glBufferData(GL_ARRAY_BUFFER, maxSize * sizeof(BoxData), NULL, GL_DYNAMIC_DRAW);

		// Set up base quad pointer
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, quadID);
		glVertexAttribPointer(
			0, // layout = 0
			3, // vec3
			GL_FLOAT,
			GL_FALSE,
			0, // no need to stride
			(void*)0 // vertexes starting at 0
		);

		//set up position pointer
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			1, // layout = 1
			3, // vec3
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), // stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::xyz)) // position part of boxdata
		);

		//set up size pointer
		glEnableVertexAttribArray(2);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			2, // layout = 2
			2, // vec2
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), // stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::wh)) // size part of boxdata
		);

		//set up rotation pointer
		glEnableVertexAttribArray(3);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			3, // layout = 3
			1, // float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), // stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::rotation)) // rotation value
		);

		//Set up texture access pointer
		glEnableVertexAttribArray(4);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			4, // layout = 4
			4, // vec 4 (u,v,w,l)
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), // stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::uvwh)) // texture access
		);

		//Set up wrapfactor
		glEnableVertexAttribArray(5);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			5, //layout = 5
			1, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::wrapFactor)) // wrap factor
		);

		//Set up transparency
		glEnableVertexAttribArray(6);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			6, //layout = 6
			1, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::transparency)) // transparency
		);

		//Set up light sensitivity
		glEnableVertexAttribArray(7);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			7, //layout = 7
			1, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::lightSensitivity)) // lightSensitivity
		);

		//Set up ambient min
		glEnableVertexAttribArray(8);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			8, //layout = 8
			1, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::ambientMin)) // ambientMinimum
		);

		//Set up modulation strength
		glEnableVertexAttribArray(9);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			9, //layout = 9
			1, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::modulationStrength)) // modulationStrength
		);

		//Set up modulation values
		glEnableVertexAttribArray(10);
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		glVertexAttribPointer(
			10, //layout = 9
			3, //single float
			GL_FLOAT,
			GL_FALSE,
			sizeof(BoxData), //stride the length of boxdata
			(void*)(offsetof(BoxData, BoxData::modulationValues)) // modulationValues
		);

		//set up striding
		glVertexAttribDivisor(0, 0); // base quad
		glVertexAttribDivisor(1, 1); // position
		glVertexAttribDivisor(2, 1); // size
		glVertexAttribDivisor(3, 1); // rotation
		glVertexAttribDivisor(4, 1); // texture access
		glVertexAttribDivisor(5, 1); // wrapfactor
		glVertexAttribDivisor(6, 1); // transparency
		glVertexAttribDivisor(7, 1); // light sensitivity
		glVertexAttribDivisor(8, 1); // ambient minimum
		glVertexAttribDivisor(9, 1); // modulationStrength
		glVertexAttribDivisor(10, 1); // modulationValues
	}

	// Render what there, the correct vao has been bound
	void render(int count) {
		// Draw
		glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, count);
	}

	VAOBoxData(int maxSize) : VAOBuffer<VAOBoxData, BoxData>(maxSize) {
		

	}

};


#endif