import sys, os, subprocess, shutil, time


BUILDDIR = os.path.abspath("build")
NINJA_EXE = "ninja.exe"
NINJA_BUILD_FILE = "build/build.ninja"
CALL_PATH = os.getcwd()
TOOL_PATH = sys.path[0] + "/"
TOOLCHAIN_PATH = os.path.dirname(sys.path[0])

NO_EMOJI = False
NO_COLOR = False

SELECTION = None
SECONDARY = None
CMAKE_EXTRA = "-DTOOLCHAIN_OFFSET:STRING={} ".format(TOOLCHAIN_PATH)

SKIP_PREBUILD = False
ONLY_CONFIG = False
NEW_BUILD = False
NO_NINJA = False


class Text:
    @staticmethod
    def error(text):
        return "\033[91m\033[1m\033[4m" + text + "\033[0m"

    @staticmethod
    def recoverableError(text):
        return "\033[31m" + text + "\033[0m"

    @staticmethod
    def underline(text):
        return "\033[4m" + text + "\033[0m"

    @staticmethod
    def bold(text):
        return "\033[1m" + text + "\033[0m"

    @staticmethod
    def header(text):
        return "\033[1m\033[4m" + text + "\033[0m"

    @staticmethod
    def warning(text):
        return "\033[93m\033[1m" + text + "\033[0m"

    @staticmethod
    def important(text):
        return "\033[94m\033[1m" + text + "\033[0m"

    @staticmethod
    def reallyImportant(text):
        return "\033[94m\033[1m\033[4m" + text + "\033[0m"

    @staticmethod
    def green(text):
        return "\033[92m" + text + "\033[0m"

    @staticmethod
    def success(text):
        return "\033[92m\033[1m" + text + "\033[0m"

    @staticmethod
    def red(text):
        return "\033[91m" + text + "\033[0m"

    @staticmethod
    def blue(text):
        return "\033[94m" + text + "\033[0m"

    @staticmethod
    def cyan(text):
        return "\033[96m" + text + "\033[0m"

    @staticmethod
    def magenta(text):
        return "\033[95m" + text + "\033[0m"

    @staticmethod
    def gray(text):
        return "\033[0;90m" + text + "\033[0m"

    @staticmethod
    def yellow(text):
        return "\033[93m" + text + "\033[0m"

    @staticmethod
    def darkYellow(text):
        return "\033[33m" + text + "\033[0m"

    @staticmethod
    def darkGreen(text):
        return "\033[32m" + text + "\033[0m"

    @staticmethod
    def darkRed(text):
        return "\033[31m" + text + "\033[0m"

    @staticmethod
    def darkBlue(text):
        return "\033[34m" + text + "\033[0m"

    @staticmethod
    def darkCyan(text):
        return "\033[36m" + text + "\033[0m"

    @staticmethod
    def darkMagenta(text):
        return "\033[35m" + text + "\033[0m"


exitCode = 0
exitError = None


def runCommand(cmd: str):
    global exitCode, exitError
    print()
    result = subprocess.run(cmd, shell=True)
    exitCode = result.returncode
    exitError = result.stderr
    return exitCode


usageMap = {
    "Valid options": Text.header("Valid options"),
    "Valid flags": Text.header("Valid flags"),
    "Prebuild Script": Text.header("Prebuild Script"),
    "Example Usage": Text.header("Example Usage"),
    "build": Text.warning("build"),
    "upload": Text.warning("upload"),
    "clean": Text.warning("clean"),
    "reset": Text.warning("reset"),
    "config": Text.warning("config"),
    "disable": Text.warning("disable"),
    "s": Text.gray("-s"),
    "com_port": Text.bold(Text.darkCyan("com_port")),
    "cmake_defs": Text.bold(Text.gray("cmake_defs")),
    "Pre_Build": Text.magenta("`Pre_Build`"),
    "bat": Text.cyan("`.bat`"),
    "ps1": Text.cyan("`.ps1`"),
    "py": Text.cyan("`.py`"),
    "Usage": "{} [{}] [{}] [{}]".format(
        Text.important("config.py"),
        Text.warning("option"),
        Text.bold(Text.gray("-s")),
        Text.bold(Text.gray("cmake_defs")) + "|" + Text.bold(Text.darkCyan("com_port")),
    ),
    "exUsage": "{} {} {}".format(
        Text.important("config.py"), Text.warning("build"), Text.gray("-s -DCUSTOM_BUILD_PATH_PREFIX:STRING=build/Pre_Build/")
    ),
}

msg = """

    {Usage}
    
    {Valid options}
    
        {clean}             \t: Cleanup build files
        {build}\t[{cmake_defs}]\t: Build project, configuring if necessary
        {upload}\t[{com_port}]\t: Upload binary file to a connected teensy
        {disable}\t[{com_port}]\t: Put a connected teensy into programming mode
        {reset}\t[{cmake_defs}]\t: Refresh project to a clean configured state
        {config}\t[{cmake_defs}]\t: Reconfigure cmake project, can pass
                            \t    extra defines {cmake_defs} for cmake
    {Valid flags}
    
        {s}                 \t: Skip any {Pre_Build} script that exists
    
    {Prebuild Script}
    
    If a script is named {Pre_Build} and is at the root of a project
    it will be run before configuring CMake
    It can be a {bat}, {ps1}, or {py}
    Only one is run, prefering the file type is that order
    
    {Example Usage}
    
    {exUsage}

""".format_map(
    usageMap
)


def usage():
    print(msg)
    sys.exit()


def endScript(errMsg: str = None):
    global exitCode, exitError
    if exitCode != 0 or errMsg:
        if errMsg:
            print(errMsg)
        if exitError:
            print()
            print(bytes.decode(exitError))
        print(Text.error("\nTask Failed ❌"))
        sys.exit(1)
    else:
        print(Text.success("\nTask Succeeded ✔"))
        sys.exit()


TEENSY_CORE_PREFIX = "TEENSY_CORE_NAME:INTERNAL="
FINAL_OUTPUT_FILE_PREFIX = "FINAL_OUTPUT_FILE:INTERNAL="
TEENSY_CORE_NAME = None
FINAL_OUTPUT_FILE = None


def populateCMAKEVars():
    global TEENSY_CORE_NAME, FINAL_OUTPUT_FILE
    with open(BUILDDIR + "\\CMakeCache.txt", "r") as f:
        for line in f:
            if line.find(FINAL_OUTPUT_FILE_PREFIX) != -1:
                FINAL_OUTPUT_FILE = line.removeprefix(FINAL_OUTPUT_FILE_PREFIX).rstrip()
            elif line.find(TEENSY_CORE_PREFIX) != -1:
                TEENSY_CORE_NAME = line.removeprefix(TEENSY_CORE_PREFIX).rstrip()


def compile():
    global FINAL_OUTPUT_FILE
    print(Text.reallyImportant("\nBuilding ⏳"))
    if runCommand("cd build && " + TOOL_PATH + NINJA_EXE + " -j16") != 0:
        endScript(Text.error("Ninja failed to build ⛔"))
    print(Text.success("\nBuild Finished 🏁"))

    populateCMAKEVars()

    if not FINAL_OUTPUT_FILE:
        endScript(Text.error("Final binary file was not found ⛔"))
    else:
        print(Text.important("Ready to Upload 🔌"))
        endScript()


def preBuild():
    if SKIP_PREBUILD:
        print(Text.warning("Skipping Pre_Build script"))
    else:
        code = None
        if os.path.isfile("Pre_Build.bat"):
            code = runCommand("Pre_Build.bat")
        elif os.path.isfile("Pre_Build.ps1"):
            code = runCommand("Pre_Build.ps1")
        elif os.path.isfile("Pre_Build.py"):
            code = runCommand("Pre_Build.py")
        else:
            return
        if code != 0:
            endScript(Text.error("Pre_Build script failed ⛔"))


def build():
    print(Text.header("Build Project"))
    if NO_NINJA:
        fullClean()

    config()
    compile()


def disable():
    runCommand(TOOL_PATH + "ComMonitor.exe {} 134 -c --priority".format(SECONDARY))


def upload():
    print(Text.header("Upload Binary ⚡"))
    populateCMAKEVars()

    if not FINAL_OUTPUT_FILE:
        endScript(Text.error("Final binary file was not found ⛔"))
    elif not SECONDARY:
        print(Text.warning("Warning! no port defined, unable to auto reboot ⚠"))
    else:
        disable()

    time.sleep(1.5)

    tries = 1

    while True:
        if runCommand(TOOL_PATH + "teensy_loader_cli.exe -mmcu={} -v {}".format(TEENSY_CORE_NAME, FINAL_OUTPUT_FILE)) == 0:
            print(Text.success("\nGood to go ✔"))
            endScript()
        elif tries == 0:
            break
        else:
            print(Text.recoverableError("Failed to upload once ✖"))
            tries -= 1

    endScript(Text.error("Failed to upload"))


def config():
    print(Text.header("Configure Project"))
    preBuild()
    print(Text.bold("Configuring CMake project ⚙"))
    if runCommand("cd build && cmake .. -G Ninja {}".format(CMAKE_EXTRA)) != 0:
        endScript(Text.error("\nFailed to configure cmake"))
    elif ONLY_CONFIG:
        endScript()


def clean():
    if NO_NINJA:
        print(Text.error("Project is invalid"))
        endScript(Text.recoverableError("Consider running config or reset"))
    print(Text.important("Cleaning 🧹"))
    if runCommand("cd build && " + TOOL_PATH + NINJA_EXE + " clean") != 0:
        endScript(Text.error("Error cleaning up build files"))


def fullClean():
    shutil.rmtree(BUILDDIR)
    os.mkdir(BUILDDIR)


def reset():
    global ONLY_CONFIG
    print(Text.red("Resetting Project"))
    ONLY_CONFIG = True
    if not NEW_BUILD:
        print(Text.important("Hard Cleaning 🧼🧽"))
        fullClean()
    config()


# Begin Script

if len(sys.argv) < 2:
    usage()

SELECTION = sys.argv[1].strip(" '\"").upper()

if len(sys.argv) > 2:
    SECONDARY = sys.argv[2].strip(" '\"").upper()
    SKIP_PREBUILD = SECONDARY == "-S"
    if SKIP_PREBUILD:
        CMAKE_EXTRA += " ".join(sys.argv[3:])
    else:
        CMAKE_EXTRA += " ".join(sys.argv[2:])

if not os.path.isdir(BUILDDIR):
    os.mkdir(BUILDDIR)
    NEW_BUILD = True

NO_NINJA = not os.path.isfile(NINJA_BUILD_FILE)

print()

if SELECTION == "BUILD":
    build()
elif SELECTION == "UPLOAD":
    upload()
elif SELECTION == "CONFIG":
    ONLY_CONFIG = True
    config()
elif SELECTION == "CLEAN":
    clean()
elif SELECTION == "RESET":
    reset()
elif SELECTION == "DISABLE":
    disable()

endScript()