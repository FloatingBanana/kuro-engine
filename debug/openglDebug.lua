-- https://love2d.org/forums/viewtopic.php?t=92481
-- Create OpenGL debug events to visualize on RenderDoc.

local ffi = require('ffi')
local GLdebug = {}
GLdebug.GL = {}
GLdebug.SDL = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

function GLdebug.init()
	local definitions = [[
		//---------------------
		// OpenGL
		//---------------------
		typedef char GLchar;
		typedef int GLsizei;
		typedef unsigned int GLuint;
		typedef unsigned int GLenum;

		// void glPushDebugGroup( GLenum source, GLuint id, GLsizei length, const GLchar *message );
		typedef void (APIENTRYP PFNGLPUSHDEBUGGROUPPROC) (GLenum source, GLuint id, GLsizei length, const GLchar *message);

		// void glPopDebugGroup( void );
		typedef void (APIENTRYP PFNGLPOPDEBUGGROUPPROC) (void);

		//---------------------
		// SDL
		//---------------------
		typedef bool SDL_bool;
		SDL_bool SDL_GL_ExtensionSupported( const char *extension );
		void* SDL_GL_GetProcAddress( const char *proc );
	]]

	if ffi.os == "Windows" then
		definitions = definitions:gsub( "APIENTRYP", "__stdcall *" )
	else
		definitions = definitions:gsub( "APIENTRYP", "*" )
	end

	ffi.cdef(definitions)

	-- https://registry.khronos.org/OpenGL/api/GL/glext.h
	local names = {
		{"glPushDebugGroup", "PFNGLPUSHDEBUGGROUPPROC"},
		{"glPopDebugGroup", "PFNGLPOPDEBUGGROUPPROC"}
	}
	local procName = ""
	local GLname = ""

	for i=1, #names do
		GLname = names[i][1]
		procName = names[i][2]
		local func = ffi.cast(procName, GLdebug.SDL.SDL_GL_GetProcAddress(GLname))

		rawset(GLdebug.GL, GLname, func)
	end
end

function GLdebug.isExtensionSupported(name)
	return GLdebug.SDL.SDL_GL_ExtensionSupported(name)
end

function GLdebug.pushEvent(message)
	GLdebug.GL.glPushDebugGroup(
		0,
		0,
		string.len(message),
		message
	)
end

function GLdebug.popEvent()
	GLdebug.GL.glPopDebugGroup()
end

function GLdebug.flushPopEvent()
	love.graphics.flushBatch()
	GLdebug.popEvent()
end

GLdebug.init()
return GLdebug