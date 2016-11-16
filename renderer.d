import derelict.sdl2.sdl;
import core.stdc.stdio : cstdio_fread=fread;
import std.algorithm;
import std.stdio;
import std.math;
import protocol;
import gfx;
import world;
import misc;
import vector;
import core.stdc.stdlib : malloc, free;

SDL_GLContext gl_context;
uint Renderer_WindowFlags=SDL_WINDOW_OPENGL;

extern(C) void ogl_reshape(int width, int height);
extern(C) void ogl_init();
extern(C) void ogl_display();
extern(C) void ogl_camera_setup(float a, float b, float x, float y, float z);
extern(C) void ogl_map_vxl_load_s(char* data);
extern(C) void ogl_chunk_rebuild_all();
extern(C) void ogl_map_set(int x, int y, int z, ulong color);
extern(C) ulong ogl_map_get(int x, int y, int z);
extern(C) void ogl_particle_create(uint color, float x, float y, float z, float velocity, float velocity_y, int amount, float min_size, float max_size);
extern(C) void ogl_overlay_setup();
extern(C) void ogl_overlay_rect(void* texture, int texture_width, int texture_height, ubyte red, ubyte green, ubyte blue, ubyte alpha, int x, int y, int w, int h);
extern(C) void ogl_overlay_rect_sub(void* texture, int texture_width, int texture_height, ubyte red, ubyte green, ubyte blue, ubyte alpha, int x, int y, int w, int h, int src_x, int src_y, int src_w, int src_h);
extern(C) void ogl_overlay_finish();
extern(C) int ogl_overlay_bind_fullness();
extern(C) void ogl_display_min();
extern(C) void ogl_render_sprite(float x, float y, float z, int xsiz, int ysiz, int zsiz, float dx, float dy, float dz, float rx, float ry, float rz);

extern(C) char* ogl_info(int i);
extern(C) int ogl_deprecation_state();

alias RendererTexture_t=void*;

//What is missing here:
//A Project2D function that converts 3D coordinates to 2D
//Renderer_UploadToTexture() function to fix minimap

void Renderer_Init(){
	SDL_GL_SetAttribute(SDL_GL_RED_SIZE,8);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE,8);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE,8);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,24);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,1);
	
	//SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE,4);
	//SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS,1);
	//SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES,4);
}

void Renderer_SetUp(){
	gl_context = SDL_GL_CreateContext(scrn_window);
	ogl_init();
	ogl_reshape(ScreenXSize,ScreenYSize);
	printf("%s\n%s\n%s\n",ogl_info(0),ogl_info(1),ogl_info(2));
}

void*[] allocated_textures;

void Renderer_UnInit(){
	foreach(tex; allocated_textures)
		free(tex);
}

RendererTexture_t Renderer_TextureFromSurface(SDL_Surface *srfc){
	void *mempos=malloc(srfc.w*srfc.h*4);
	if(!mempos){
		writeflnlog("SHTF: MALLOC FAILED\n");
	}
	(cast(ubyte*)mempos)[0..srfc.w*srfc.h*4]=(cast(ubyte*)srfc.pixels)[0..srfc.w*srfc.h*4];
	RendererTexture_t ret=mempos;
	allocated_textures~=ret;
	return cast(RendererTexture_t)ret;
}

void Renderer_UploadToTexture(SDL_Surface *srfc, RendererTexture_t tex){
	(cast(uint*)tex)[0..srfc.w*srfc.h]=(cast(uint*)srfc.pixels)[0..srfc.w*srfc.h];
}

void Renderer_DestroyTexture(RendererTexture_t tex){
	if(allocated_textures.canFind(tex))
		allocated_textures=allocated_textures.remove(allocated_textures.countUntil(tex));
	free(tex);
}

void Renderer_Blit2D(RendererTexture_t tex, uint[2]* size, SDL_Rect *dstr, ubyte alpha=255, ubyte[3] *ColorMod=null, SDL_Rect *srcr=null){
	ubyte[3] cmod;
	if(ColorMod){
		cmod=*ColorMod;
	}
	else{
		cmod=[255, 255, 255];
	}
	if(!srcr){
		ogl_overlay_rect(tex,(*size)[0],(*size)[1], cmod[0], cmod[1], cmod[2], alpha, dstr.x, dstr.y, dstr.w, dstr.h);
	}
	else{
		ogl_overlay_rect_sub(tex,(*size)[0],(*size)[1], cmod[0], cmod[1], cmod[2], alpha, dstr.x, dstr.y, dstr.w, dstr.h,
		srcr.x, srcr.y, srcr.w, srcr.h);
	}
}

int Rendered_3D=-1;

void Renderer_StartRendering(bool render_3D){
	Rendered_3D=render_3D;
	if(render_3D)
		ogl_display();
	else
		ogl_display_min();
}

void Renderer_Start2D(){
	ogl_overlay_setup();
}

void Renderer_ShowInfo(){
	int state = ogl_deprecation_state();
	if(state>0) {
		Render_Text_Line(0,cast(int)(ScreenYSize-FontHeight/16*2.5F),0xFFFFFF,"GPU deprecated!",font_texture,FontWidth,FontHeight,LetterPadding,2.5F,2.5F);
		if(state&1) {
			Render_Text_Line(0,cast(int)(ScreenYSize-FontHeight/16*2.5F*2.0F),0xFFFFFF,"power of 2 tex limit",font_texture,FontWidth,FontHeight,LetterPadding,2.5F,2.5F);
		}
		if(state&2) {
			Render_Text_Line(0,cast(int)(ScreenYSize-FontHeight/16*2.5F*3.0F),0xFFFFFF,"ogl1.4 only",font_texture,FontWidth,FontHeight,LetterPadding,2.5F,2.5F);
		}
	}
}

void Renderer_Finish2D(){
	ogl_overlay_finish();
}

void Renderer_FinishRendering(){
	SDL_GL_SwapWindow(scrn_window);
}

void Renderer_LoadMap(ubyte[] map){
	ogl_map_vxl_load_s(cast(char*)map.ptr);
	ogl_chunk_rebuild_all();
}

void Renderer_SetCamera(float xrotation, float yrotation, float tilt, float xfov, float yfov, float xpos, float ypos, float zpos){
	ogl_camera_setup((-xrotation+90.0F)/180.0F*3.14159F, (yrotation+90.0F)/180.0F*3.14159F, xpos, 64.0-ypos, zpos);
}

void Renderer_DrawVoxels(){}

//PLS ADD: (returns whether object is visible, scrx/scry are screen coords of the centre, dist is distance
bool Project2D(float xpos, float ypos, float zpos, float *dist, out int scrx, out int scry){
	return false;
}

int[2] Project2D(float xpos, float ypos, float zpos, float *dist){
	return [-10000, -10000];
}

//Note: It's ok if you don't even plan on implementing blur in your renderer, BUT ONLY FOR VERY SHITTY RENDERERS OR CPU ONES THAT CAN'T AFFORD THIS
void Set_Blur(float amount){
	
}

uint Voxel_FindFloorZ(uint x, uint y, uint z){
	for(y=0;y<MapYSize; y++){
		if(Voxel_IsSolid(x, y, z)){
			return y;
		}
	}
	return 0;
}

//Actually these shouldn't belong here, but a renderer can bring its own map memory format
bool Voxel_IsSolid(uint x, uint y, uint z){
	return ogl_map_get(x,64-y-1,z)!=0xFFFFFFFF;
}

//0xARGB, not 0xABGR '-'
void Voxel_SetColor(uint x, uint y, uint z, uint col){
	ogl_map_set(x,64-y-1,z,((col>>16)&255) | (((col>>8)&255)<<8) | ((col&255)<<16));
}

void Voxel_SetShade(uint x, uint y, uint z, ubyte shade){
	
}

uint Voxel_GetColor(uint x, uint y, uint z){
	uint col=ogl_map_get(x,64-y-1,z)&0xFFFFFF;
	return ((col>>16)&255) | (((col>>8)&255)<<8) | ((col&255)<<16);
}

void Voxel_Remove(uint x, uint y, uint z){
	uint col = ogl_map_get(x,64-y-1,z)&0xFFFFFF;
	ogl_map_set(x,64-y-1,z,0xFFFFFFFF);
	ogl_particle_create(col,x+0.5F,(64-y-1)+0.5F,z+0.5F,2.5F,1.0F,16,0.1F,0.25F);
}

void Renderer_DrawSprite(KV6Sprite_t *spr){
	ogl_render_sprite(spr.xpos,64.0F-spr.ypos,spr.zpos,spr.model.xsize,spr.model.ysize,spr.model.zsize,spr.xdensity,spr.ydensity,spr.zdensity,spr.rhe,-spr.rti+90.0F,spr.rst);
}

void Renderer_SetFog(uint fogcolor, uint fogrange){
}

extern(C) struct KV6Voxel_t{
	uint color;
	ushort ypos;
	char visiblefaces, normalindex;
}

extern(C) struct KV6Model_t{
	int xsize, ysize, zsize;
	float xpivot, ypivot, zpivot;
	int voxelcount;
	extern(C) KV6Model_t *lowermip;
	extern(C) KV6Voxel_t[] voxels;
	extern(C) uint[] xlength;
	extern(C) ushort[][] ylength;
	KV6Model_t *copy(){
		KV6Model_t *newmodel=new KV6Model_t;
		newmodel.xsize=xsize; newmodel.ysize=ysize; newmodel.zsize=zsize;
		newmodel.xpivot=xpivot; newmodel.ypivot=ypivot; newmodel.zpivot=zpivot;
		newmodel.voxelcount=voxelcount; newmodel.lowermip=lowermip;
		newmodel.voxels.length=voxels.length; newmodel.voxels[]=voxels[];
		newmodel.xlength.length=xlength.length; newmodel.xlength[]=xlength[];
		newmodel.ylength.length=ylength.length; newmodel.ylength[]=ylength[];
		return newmodel;
	}
}

extern(C) struct KV6Sprite_t{
	float rhe, rti, rst;
	float xpos, ypos, zpos;
	float xdensity, ydensity, zdensity;
	uint color_mod, replace_black;
	ubyte check_visibility;
	KV6Model_t *model;
}

int freadptr(void *buf, uint bytes, File f){
	if(!buf){
		writeflnlog("freadptr called with void buffer");
		return 0;
	}
	return cast(int)cstdio_fread(buf, bytes, 1u, f.getFP());
}

KV6Model_t *Load_KV6(string fname){
	File f=File(fname, "rb");
	if(!f.isOpen()){
		writeflnerr("Couldn't open %s", fname);
		return null;
	}
	string fileid;
	fileid.length=4;
	freadptr(cast(void*)fileid.ptr, 4, f);
	if(fileid!="Kvxl"){
		writeflnerr("Model file %s is not a valid KV6 file (wrong header)", fname);
		return null;
	}
	KV6Model_t *model=new KV6Model_t;
	freadptr(&model.xsize, 4, f); freadptr(&model.zsize, 4, f); freadptr(&model.ysize, 4, f);
	if(model.xsize<0 || model.ysize<0 || model.zsize<0){
		writeflnerr("Model file %s has invalid size (%d|%d|%d)", fname, model.xsize, model.ysize, model.zsize);
		return null;
	}
	freadptr(&model.xpivot, 4, f); freadptr(&model.zpivot, 4, f); freadptr(&model.ypivot, 4, f);
	freadptr(&model.voxelcount, 4, f);
	if(model.voxelcount<0){
		writeflnerr("Model file %s has invalid voxel count (%d)", fname, model.voxelcount);
		return null;
	}
	model.voxels=new KV6Voxel_t[](model.voxelcount);
	for(uint i=0; i<model.voxelcount; i++){
		freadptr(&model.voxels[i], model.voxels[i].sizeof, f);
	}
	model.xlength=new uint[](model.xsize);
	for(uint x=0; x<model.xsize; x++)
		freadptr(&model.xlength[x], 4, f);
	model.ylength=new ushort[][](model.xsize, model.zsize);
	for(uint x=0; x<model.xsize; x++)
		for(uint z=0; z<model.zsize; z++)
			freadptr(&model.ylength[x][z], 2, f);
	string palette;
	palette.length=4;
	freadptr(cast(void*)palette.ptr, 4, f);
	if(!f.eof()){
		if(palette=="SPal"){
			writeflnlog("Note: File %s contains a useless suggested palette block (SLAB6)", fname);
		}
		else{
			writeflnlog("Warning: File %s contains invalid data after its ending (corrupted file?)", fname);
			writeflnlog("KV6 size: (%d|%d|%d), pivot: (%d|%d|%d), amount of voxels: %d", model.xsize, model.ysize, model.zsize, 
			model.xpivot, model.ypivot, model.zpivot, model.voxelcount);
		}
	}
	f.close();
	return model;
}

uint Count_KV6Blocks(KV6Model_t *model, uint dstx, uint dsty){
	uint index=0;
	for(uint x=0; x<dstx; x++)
		index+=model.xlength[x];
	uint xy=dstx*model.ysize;
	for(uint y=0; y<dsty; y++)
		index+=model.ylength[dstx][y];
	return index;
}

void Renderer_Draw3DParticle(float x, float y, float z, int w, int h, uint col){
}

void Renderer_Draw3DParticle(Vector3_t *pos, int w, int h, uint col){
	return Renderer_Draw3DParticle(pos.x, pos.y, pos.z, w, h, col);
}

void Renderer_DrawSmokeCircle(float x, float y, float z, int radius, uint color, uint alpha, float dist){
	
}
