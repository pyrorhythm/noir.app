import Cocoa

let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
if handle == nil {
    print("Failed to load SkyLight")
    exit(1)
}

let sym = dlsym(handle, "CGSSetWindowMargin")
if sym == nil {
    print("CGSSetWindowMargin not found")
} else {
    print("CGSSetWindowMargin found!")
}

let sym2 = dlsym(handle, "CGSSetWorkspaceMargin")
if sym2 == nil {
    print("CGSSetWorkspaceMargin not found")
} else {
    print("CGSSetWorkspaceMargin found!")
}
