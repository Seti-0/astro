#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class NativeUtility: public Object {
    GDCLASS(NativeUtility, Object)
protected:
    static void _bind_methods();

public:
    static void test();
};


}

#endif