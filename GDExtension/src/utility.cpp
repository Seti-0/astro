#include "utility.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void NativeUtility::_bind_methods() {
    ClassDB::bind_static_method("NativeUtility", D_METHOD("test"), &NativeUtility::test);
}

void NativeUtility::test() {
    UtilityFunctions::print("Hello world from astro-native!!");
}