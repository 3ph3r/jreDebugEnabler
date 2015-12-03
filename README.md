JRE Debug Enabler
===
Official JRE distribution comes compiled without debugging information. This script aims to provide an easy way to create your own portable JRE with all debugging information.

What you need?
---
Script requires following utils in ```PATH``` variable:
* [7z](http://www.7-zip.org/)
* [find](https://www.cygwin.com/) - not to confuse with Windows built-in ```find``` command
* [ResourcesExtract](http://www.nirsoft.net/utils/resources_extract.html)

To create JRE with all debugging information you will also need official JDK installer (available [here](http://www.oracle.com/technetwork/java/javase/downloads/index.html)).

What it does?
---
Script performs following operations:

1. Extracting from JDK installer:
  * ```javac``` compiler
  * bundled JRE distribution
  * packed JRE sources
2. Extracting JRE sources
3. Compiling extracted sources
4. Packing compiled sources
5. Combining the result with extracted earlier JRE

Step by step
---
In order to make use of the script do the following:

1. Place JDK installer named ```jdk-*-windows-i586.exe``` (```*``` is where Java version and optional update are) in folder named ```JDK_DIR```
2. Run the script

After few minutes finished JRE will be ready in ```RESULT``` folder.

What's missing?
---
- [ ] 64bit JDK support - apart from different installer name there is slight difference in installer's content
- [ ] old Java support - current release will work with jdk-6u10 and newer; older installers have different inner structure
