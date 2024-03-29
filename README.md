# SGAS
This is a set of scripts for Godot XR, providing the core functionality of a gesture-based action system. Note that this is not gesture recognition.

**S**imple **G**esture-based **A**ction **S**ystem uses ShapeCasts that must be collided with in a specific order, to then activate an action.<br>
- **PoseNodes** represent poses. They communicate with their PoseComponents, and release signals.<br>
- Each PoseNode must have at least one child **PoseComponent**. They use ShapeCasts and determine whether the colliding nodes match the set conditions.<br>
- **GestureNodes** communicate which PoseNodes they each want enabled, and emit a signal (gesture_activated) when certain events have passed (e.g. certain poses activated, and certain amount of time passed).<br>

## Installation & usage
To install SGAS as intended, you just need the 4 .gd files found in *main*.<br>
This repo also contains an example of how one may use SGAS. To try this example/demo out, clone both the *example* and the *main* folders into a godot project with XR enabled. Then, find the *sgas_example_scene* scene in the *example* folder, open it (in Godot). This scene contains an action which we want to activate (*iwanttomakethisred*), a gesture (SGAS), and two poses (SGAS).<br>

## Dependencies and issues
I have developed this on PCVR (CV1) whilst using XRTools. As far as I'm aware there should be no issue using this without XRTools or using this on standalone VR, but I cannot attest this.<br>
I am new to Godot and programming in general, so some things may be completely non-sensical.<br>

Let me know if you have any suggestions, questions, or other such. You can find me in the Godot discord server (@pisslover72).
