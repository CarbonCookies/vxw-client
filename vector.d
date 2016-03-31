import std.math;
import misc;

T degsin(T)(T val){
	return sin(val*PI/180.0);
}

T degcos(T)(T val){
	return cos(val*PI/180.0);
}

struct Vector3_t{
	float x, y, z;
	@property typeof(x) length(){
		return vector_length();
	}
	@property void length(typeof(x) newlength){
		this=this*newlength/vector_length();
	}
    alias opDollar=length;
	this(Vector3_t vec){
		this=vec;
	}
	this(T)(T[] val){
		x=cast(typeof(x))val[0]; y=cast(typeof(y))val[1]; z=cast(typeof(z))val[2];
	}
	this(T)(T val) if(__traits(isScalar, val)){
		x=cast(typeof(x))val; y=cast(typeof(y))val; z=cast(typeof(z))val;
	}
	this(typeof(x) ix, typeof(y) iy, typeof(z) iz){
		x=ix; y=iy; z=iz;
	}
	this(T1, T2, T3)(T1 ix, T2 iy, T3 iz){
		x=cast(typeof(x))ix; y=cast(typeof(y))iy; z=cast(typeof(z))iz;
	}
	Vector3_t opBinary(string op)(Vector3_t arg){
		return Vector3_t(mixin("x"~op~"arg.x"), mixin("y"~op~"arg.y"), mixin("z"~op~"arg.z"));
	}
	Vector3_t opBinary(string op, T)(T arg[]){
		return Vector3_t(mixin("x"~op~"arg[0]"), mixin("y"~op~"arg[1]"), mixin("z"~op~"arg[2]"));
	}
	Vector3_t opBinary(string op, T)(T arg){
		return Vector3_t(mixin("x"~op~"arg"), mixin("y"~op~"arg"), mixin("z"~op~"arg"));
	}
	Vector3_t opOpAssign(string op)(Vector3_t arg){
		this=this.opBinary!(op)(arg);
		return this;
	}
	Vector3_t opOpAssign(string op, T)(T arg){
		this=this.opBinary!(op)(arg);
		return this;
	}
	Vector3_t opOpAssign(string op, T)(T[] arg){
		this=this.opBinary!(op)(arg);
		return this;
	}
	float opIndex(T)(T index){
		static if((cast(int)T)==0)
			return x;
		else if((cast(int)T)==1)
			return y;
		else if((cast(int)T)==2)
			return z;
		assert(1);
	}
	
	typeof(x) vector_length(){return std.math.sqrt(x*x+y*y+z*z);}
	
	Vector3_t cossin(){return Vector3_t(degcos(x), degsin(y), degsin(z));}
	Vector3_t sincos(){return Vector3_t(degsin(x), degcos(y), degcos(z));}
	
	Vector3_t sincossin(){return Vector3_t(degsin(x), degcos(y), degsin(z));}
	
	Vector3_t sin(){return Vector3_t(degsin(x), degsin(y), degsin(z));}
	Vector3_t cos(){return Vector3_t(degcos(x), degcos(y), degcos(z));}
	
	Vector3_t rotdir(){return Vector3_t(degcos(x), degsin(x), degcos(y));}
	
	Vector3_t abs(){return (this/this.length);}
	Vector3_t vecabs(){return Vector3_t(fabs(x), fabs(y), fabs(z));}
	
	Vector3_t rotate(Vector3_t rot){
		Vector3_t rrot=rot;
		rrot.x=rot.z; rrot.z=rot.x;
		return rotate_raw(rrot);
	}

	Vector3_t rotate_raw(Vector3_t rot){
		Vector3_t ret=this, tmp=this;
		Vector3_t vsin=rot.sin(), vcos=rot.cos();
		ret.y=tmp.y*vcos.x-tmp.z*vsin.x; ret.z=tmp.y*vsin.x+tmp.z*vcos.x;
		tmp.x=ret.x; tmp.z=ret.z;
		ret.z=tmp.z*vcos.y-tmp.x*vsin.y; ret.x=tmp.z*vsin.y+tmp.x*vcos.y;
		tmp.x=ret.x; tmp.y=ret.y;
		ret.x=tmp.x*vcos.z-tmp.y*vsin.z; ret.y=tmp.x*vsin.z+tmp.y*vcos.z;
		return ret;
	}
	
	Vector3_t RotationAsDirection(){
		/*Vector3_t dir=Vector3_t(1.0);
		dir=dir.rotate(this.cossin());
		return dir;*/
		float cx=degcos(this.x);
		float sy=degsin(this.y);
		float cz=degsin(this.x);
		return Vector3_t(cx, sy, cz);
	}
	
	Vector3_t DirectionAsRotation(){
		float rx=atan2(this.z, this.x)*180.0/PI-90.0;
		float ry=asin(this.y)*180.0/PI+90.0;
		float rz=0.0;
		return Vector3_t(rx, ry, rz);
	}
	
	typeof(x) dot(T)(T arg){
		Vector3_t vec=Vector3_t(arg);
		return x*vec.x+y*vec.y+z*vec.z;
	}
	typeof(x) dot(Vector3_t vec){
		return x*vec.x+y*vec.y+z*vec.z;
	}
	
	typeof(x)[3] opCast(){
		return [x, y, z];
	}
	
	Vector3_t filter(T)(T[] filterarr){
		return filter(filterarr[0], filterarr[1], filterarr[2]);
	}
	Vector3_t filter(TFX, TFY, TFZ)(TFX filterx, TFY filtery, TFZ filterz){
		return Vector3_t(filterx ? x : 0.0, filtery ? y : 0.0, filterz ? z : 0.0);
	}
	Vector3_t filter(alias filterx, alias filtery, alias filterz)(){
		mixin("return Vector3_t("~(filterx ? "x," : "0,")~(filtery ? "y," : "0,")~(filterz ? "z," : "0,")~");");
	}
}