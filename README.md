# raytracer-opengl
Raytracer OpenGL(GLSL) implementation <br /><br />
### Roughness = 0.0
<img src="demos/roughness_0_0.png" align="middle" /><br /><br />
### Roughness = 0.3
<img src="demos/roughness_0_3.png" align="middle" /><br /><br />
### Roughness = 0.5
<img src="demos/roughness_0_5.png" align="middle" /><br /><br />
### Roughness = 0.9
<img src="demos/roughness_0_9.png" align="middle" />

# Setup
- Open vscode
- Install glslCanvas from https://marketplace.visualstudio.com/items?itemName=circledev.glsl-canvas
(glslCanvas is an extension for vscode that visualizes shader in realtime as you code)
- Open the main.glsl file in vscode
- activate glslCanvas extention
- [ctrl]+[shift]+P then type 'Show glslCanvas' without(') and press enter
- The scene should start displaying

# Parameters
- Render parameters (Roughness, Bounces, Samples etc) start at line numbers 8
- Ambient light properties are at line numbers 18,19
- Lights definition and properties start at line 271
- Sphere objects definition and properties start at line 290
- Plane objects definition and properties start at line 312
- Camera definition and properties start at line 352

### Note
If you add or remove an object from the scene, be sure to adjust the static object count at line 22 to 24 accordingly

Much much faster than python implementation of raytracer (60 fps)
