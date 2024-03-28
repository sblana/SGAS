# SGAS
This is a set of scripts for Godot XR, providing the core functionality of a gesture-based action system. Note that this is not gesture recognition.

**S**imple **G**esture-based **A**ction **S**ystem uses ShapeCasts that must be collided with in a specific order, to then activate an action.<br>
- **PoseNodes** represent poses. They communicate with their PoseComponents, and release signals.<br>
- Each PoseNode must have at least one child **PoseComponent**. They use ShapeCasts and determine whether the colliding nodes match the set conditions.<br>
- **GestureNodes** communicate which PoseNodes they each want enabled, and emit a signal when certain events have passed (e.g. certain poses activated, and certain amount of time passed).<br>

## Dependencies and issues
I have developed this on PCVR (CV1) whilst using XRTools. As far as I'm aware there should be no issue using this without XRTools or using this on standalone VR, but I cannot attest this.<br>
I am new to Godot and programming in general, so some things may be completely non-sensical.<br>

Let me know if you have any suggestions, questions, or other such. You can find me in the Godot discord server (@pisslover72).
