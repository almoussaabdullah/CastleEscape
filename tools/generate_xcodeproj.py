#!/usr/bin/env python3
"""Generates CastleEscape.xcodeproj from the files on disk.

The generator is deterministic: object IDs are derived from paths, so re-running it after
adding files only changes the lines that need to change. Run from the repository root:

    python3 tools/generate_xcodeproj.py

XcodeGen users can use project.yml instead; both describe the same project.
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_NAME = "CastleEscape"
TEST_NAME = "CastleEscapeTests"
BUNDLE_ID = "agency.go360.castleescape"
DEPLOYMENT_TARGET = "17.0"
OBJECT_VERSION = 56

SOURCE_EXT = {".swift"}
RESOURCE_EXT = {".xcassets", ".xcstrings", ".json"}
FILE_TYPES = {
    ".swift": "sourcecode.swift",
    ".xcassets": "folder.assetcatalog",
    ".xcstrings": "text.json.xcstrings",
    ".json": "text.json",
    ".md": "net.daringfireball.markdown",
}


def uid(key: str) -> str:
    return hashlib.md5(key.encode("utf-8")).hexdigest()[:24].upper()


def quote(value: str) -> str:
    """Quote a pbxproj string when it is not a plain identifier."""
    safe = all(ch.isalnum() or ch in "._/" for ch in value) and value
    return value if safe else '"' + value.replace('"', '\\"') + '"'


class Project:
    def __init__(self):
        self.build_files = []      # (id, fileref_id, name, phase)
        self.file_refs = []        # (id, name, path, filetype, is_product)
        self.groups = {}           # group_id -> (name, path, children_ids)
        self.group_order = []
        self.app_sources = []
        self.app_resources = []
        self.test_sources = []

    # ---- tree scanning ---------------------------------------------------
    def scan(self, folder_name, rel_root, target_sources, target_resources=None):
        """Builds groups mirroring the folder structure."""
        abs_root = os.path.join(ROOT, rel_root)
        group_id = self.add_group(folder_name, folder_name, parent=None)
        self._scan_dir(abs_root, rel_root, group_id, target_sources, target_resources)
        return group_id

    def _scan_dir(self, abs_dir, rel_dir, group_id, target_sources, target_resources):
        entries = sorted(os.listdir(abs_dir))
        # Files first, then directories, both alphabetical (Xcode-like).
        files = [e for e in entries if not os.path.isdir(os.path.join(abs_dir, e)) or e.endswith(".xcassets")]
        dirs = [e for e in entries if os.path.isdir(os.path.join(abs_dir, e)) and not e.endswith(".xcassets")]
        for name in files:
            ext = os.path.splitext(name)[1]
            if ext not in FILE_TYPES or name.startswith("."):
                continue
            rel_path = os.path.join(rel_dir, name)
            ref_id = uid("ref:" + rel_path)
            self.file_refs.append((ref_id, name, name, FILE_TYPES[ext], False))
            self.groups[group_id][2].append(ref_id)
            if ext in SOURCE_EXT:
                target_sources.append((uid("build:" + rel_path), ref_id, name, "Sources"))
            elif ext in RESOURCE_EXT and target_resources is not None:
                target_resources.append((uid("build:" + rel_path), ref_id, name, "Resources"))
        for name in dirs:
            if name.startswith("."):
                continue
            rel_path = os.path.join(rel_dir, name)
            child_group = self.add_group(name, name, parent=group_id)
            self._scan_dir(os.path.join(abs_dir, name), rel_path, child_group, target_sources, target_resources)

    def add_group(self, name, path, parent):
        key = "group:" + (path if parent is None else parent + "/" + path)
        group_id = uid(key)
        self.groups[group_id] = (name, path, [])
        self.group_order.append(group_id)
        if parent is not None:
            self.groups[parent][2].append(group_id)
        return group_id


def build_settings_block(settings, indent="\t\t\t\t"):
    lines = []
    for key in sorted(settings):
        value = settings[key]
        if isinstance(value, list):
            lines.append(f"{indent}{key} = (")
            for item in value:
                lines.append(f"{indent}\t{quote(item)},")
            lines.append(f"{indent});")
        else:
            lines.append(f"{indent}{key} = {quote(str(value))};")
    return "\n".join(lines)


PROJECT_COMMON = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
}

PROJECT_DEBUG = {
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
}

PROJECT_RELEASE = {
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
}

APP_SETTINGS = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "Castle Escape",
    "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.puzzle-games",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UIRequiresFullScreen": "YES",
    "INFOPLIST_KEY_UIStatusBarHidden": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UIViewControllerBasedStatusBarAppearance": "NO",
    "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}

TEST_SETTINGS = {
    "BUNDLE_LOADER": "$(TEST_HOST)",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID + ".tests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_HOST": f"$(BUILT_PRODUCTS_DIR)/{APP_NAME}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{APP_NAME}",
}


def generate():
    project = Project()
    app_group = project.scan(APP_NAME, APP_NAME, project.app_sources, project.app_resources)
    test_group = project.scan(TEST_NAME, TEST_NAME, project.test_sources, None)

    app_product = uid("product:app")
    test_product = uid("product:test")
    products_group = uid("group:Products")
    main_group = uid("group:main")
    app_target = uid("target:app")
    test_target = uid("target:test")
    project_id = uid("project")
    app_sources_phase = uid("phase:app:sources")
    app_frameworks_phase = uid("phase:app:frameworks")
    app_resources_phase = uid("phase:app:resources")
    test_sources_phase = uid("phase:test:sources")
    test_frameworks_phase = uid("phase:test:frameworks")
    test_resources_phase = uid("phase:test:resources")
    proxy_id = uid("proxy:test->app")
    dependency_id = uid("dependency:test->app")
    cfg_project_debug = uid("cfg:project:debug")
    cfg_project_release = uid("cfg:project:release")
    cfg_app_debug = uid("cfg:app:debug")
    cfg_app_release = uid("cfg:app:release")
    cfg_test_debug = uid("cfg:test:debug")
    cfg_test_release = uid("cfg:test:release")
    list_project = uid("cfglist:project")
    list_app = uid("cfglist:app")
    list_test = uid("cfglist:test")

    out = []
    w = out.append
    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {")
    w("\t};")
    w(f"\tobjectVersion = {OBJECT_VERSION};")
    w("\tobjects = {")

    # PBXBuildFile
    w("")
    w("/* Begin PBXBuildFile section */")
    for build_id, ref_id, name, phase in sorted(project.app_sources + project.app_resources + project.test_sources, key=lambda b: b[2]):
        w(f"\t\t{build_id} /* {name} in {phase} */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {name} */; }};")
    w("/* End PBXBuildFile section */")

    # PBXContainerItemProxy
    w("")
    w("/* Begin PBXContainerItemProxy section */")
    w(f"\t\t{proxy_id} /* PBXContainerItemProxy */ = {{")
    w("\t\t\tisa = PBXContainerItemProxy;")
    w(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
    w("\t\t\tproxyType = 1;")
    w(f"\t\t\tremoteGlobalIDString = {app_target};")
    w(f"\t\t\tremoteInfo = {APP_NAME};")
    w("\t\t};")
    w("/* End PBXContainerItemProxy section */")

    # PBXFileReference
    w("")
    w("/* Begin PBXFileReference section */")
    w(f"\t\t{app_product} /* {APP_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    w(f"\t\t{test_product} /* {TEST_NAME}.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {TEST_NAME}.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for ref_id, name, path, filetype, _ in sorted(project.file_refs, key=lambda r: r[1]):
        w(f"\t\t{ref_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {filetype}; path = {quote(path)}; sourceTree = \"<group>\"; }};")
    w("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    w("")
    w("/* Begin PBXFrameworksBuildPhase section */")
    for phase_id in (app_frameworks_phase, test_frameworks_phase):
        w(f"\t\t{phase_id} /* Frameworks */ = {{")
        w("\t\t\tisa = PBXFrameworksBuildPhase;")
        w("\t\t\tbuildActionMask = 2147483647;")
        w("\t\t\tfiles = (")
        w("\t\t\t);")
        w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup
    names = {ref_id: name for ref_id, name, _, _, _ in project.file_refs}
    for group_id, (name, _, _) in project.groups.items():
        names[group_id] = name
    w("")
    w("/* Begin PBXGroup section */")
    w(f"\t\t{main_group} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{app_group} /* {APP_NAME} */,")
    w(f"\t\t\t\t{test_group} /* {TEST_NAME} */,")
    w(f"\t\t\t\t{products_group} /* Products */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w(f"\t\t{products_group} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{app_product} /* {APP_NAME}.app */,")
    w(f"\t\t\t\t{test_product} /* {TEST_NAME}.xctest */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    for group_id in project.group_order:
        name, path, children = project.groups[group_id]
        w(f"\t\t{group_id} /* {name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        for child in children:
            w(f"\t\t\t\t{child} /* {names[child]} */,")
        w("\t\t\t);")
        w(f"\t\t\tpath = {quote(path)};")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")
    w("/* End PBXGroup section */")

    # PBXNativeTarget
    w("")
    w("/* Begin PBXNativeTarget section */")
    w(f"\t\t{app_target} /* {APP_NAME} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {list_app} /* Build configuration list for PBXNativeTarget \"{APP_NAME}\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{app_sources_phase} /* Sources */,")
    w(f"\t\t\t\t{app_frameworks_phase} /* Frameworks */,")
    w(f"\t\t\t\t{app_resources_phase} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w(f"\t\t\tname = {APP_NAME};")
    w(f"\t\t\tproductName = {APP_NAME};")
    w(f"\t\t\tproductReference = {app_product} /* {APP_NAME}.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w(f"\t\t{test_target} /* {TEST_NAME} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {list_test} /* Build configuration list for PBXNativeTarget \"{TEST_NAME}\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{test_sources_phase} /* Sources */,")
    w(f"\t\t\t\t{test_frameworks_phase} /* Frameworks */,")
    w(f"\t\t\t\t{test_resources_phase} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w(f"\t\t\t\t{dependency_id} /* PBXTargetDependency */,")
    w("\t\t\t);")
    w(f"\t\t\tname = {TEST_NAME};")
    w(f"\t\t\tproductName = {TEST_NAME};")
    w(f"\t\t\tproductReference = {test_product} /* {TEST_NAME}.xctest */;")
    w("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")

    # PBXProject
    w("")
    w("/* Begin PBXProject section */")
    w(f"\t\t{project_id} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{app_target} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w(f"\t\t\t\t\t{test_target} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w(f"\t\t\t\t\t\tTestTargetID = {app_target};")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {list_project} /* Build configuration list for PBXProject \"{APP_NAME}\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = ar;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\tar,")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {main_group};")
    w(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{app_target} /* {APP_NAME} */,")
    w(f"\t\t\t\t{test_target} /* {TEST_NAME} */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")

    # PBXResourcesBuildPhase
    w("")
    w("/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{app_resources_phase} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for build_id, _, name, phase in sorted(project.app_resources, key=lambda b: b[2]):
        w(f"\t\t\t\t{build_id} /* {name} in {phase} */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w(f"\t\t{test_resources_phase} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase
    w("")
    w("/* Begin PBXSourcesBuildPhase section */")
    for phase_id, files in ((app_sources_phase, project.app_sources), (test_sources_phase, project.test_sources)):
        w(f"\t\t{phase_id} /* Sources */ = {{")
        w("\t\t\tisa = PBXSourcesBuildPhase;")
        w("\t\t\tbuildActionMask = 2147483647;")
        w("\t\t\tfiles = (")
        for build_id, _, name, phase in sorted(files, key=lambda b: b[2]):
            w(f"\t\t\t\t{build_id} /* {name} in {phase} */,")
        w("\t\t\t);")
        w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")

    # PBXTargetDependency
    w("")
    w("/* Begin PBXTargetDependency section */")
    w(f"\t\t{dependency_id} /* PBXTargetDependency */ = {{")
    w("\t\t\tisa = PBXTargetDependency;")
    w(f"\t\t\ttarget = {app_target} /* {APP_NAME} */;")
    w(f"\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;")
    w("\t\t};")
    w("/* End PBXTargetDependency section */")

    # XCBuildConfiguration
    w("")
    w("/* Begin XCBuildConfiguration section */")

    def config(cfg_id, name, settings):
        w(f"\t\t{cfg_id} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w("\t\t\tbuildSettings = {")
        w(build_settings_block(settings))
        w("\t\t\t};")
        w(f"\t\t\tname = {name};")
        w("\t\t};")

    config(cfg_project_debug, "Debug", {**PROJECT_COMMON, **PROJECT_DEBUG})
    config(cfg_project_release, "Release", {**PROJECT_COMMON, **PROJECT_RELEASE})
    config(cfg_app_debug, "Debug", APP_SETTINGS)
    config(cfg_app_release, "Release", APP_SETTINGS)
    config(cfg_test_debug, "Debug", TEST_SETTINGS)
    config(cfg_test_release, "Release", TEST_SETTINGS)
    w("/* End XCBuildConfiguration section */")

    # XCConfigurationList
    w("")
    w("/* Begin XCConfigurationList section */")
    for list_id, owner, debug_id, release_id in (
        (list_project, f"PBXProject \"{APP_NAME}\"", cfg_project_debug, cfg_project_release),
        (list_app, f"PBXNativeTarget \"{APP_NAME}\"", cfg_app_debug, cfg_app_release),
        (list_test, f"PBXNativeTarget \"{TEST_NAME}\"", cfg_test_debug, cfg_test_release),
    ):
        w(f"\t\t{list_id} /* Build configuration list for {owner} */ = {{")
        w("\t\t\tisa = XCConfigurationList;")
        w("\t\t\tbuildConfigurations = (")
        w(f"\t\t\t\t{debug_id} /* Debug */,")
        w(f"\t\t\t\t{release_id} /* Release */,")
        w("\t\t\t);")
        w("\t\t\tdefaultConfigurationIsVisible = 0;")
        w("\t\t\tdefaultConfigurationName = Release;")
        w("\t\t};")
    w("/* End XCConfigurationList section */")

    w("\t};")
    w(f"\trootObject = {project_id} /* Project object */;")
    w("}")

    proj_dir = os.path.join(ROOT, f"{APP_NAME}.xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    with open(os.path.join(proj_dir, "project.pbxproj"), "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    # Workspace wrapper (Xcode creates this on open, but it is harmless to ship).
    ws_dir = os.path.join(proj_dir, "project.xcworkspace")
    os.makedirs(ws_dir, exist_ok=True)
    with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

    # Shared scheme with build + test actions.
    scheme_dir = os.path.join(proj_dir, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    with open(os.path.join(scheme_dir, f"{APP_NAME}.xcscheme"), "w", encoding="utf-8") as f:
        f.write(SCHEME_TEMPLATE.format(app=APP_NAME, tests=TEST_NAME, app_target=app_target, test_target=test_target))

    print(f"wrote {proj_dir}: {len(project.app_sources)} app sources, {len(project.app_resources)} resources, {len(project.test_sources)} test sources")


SCHEME_TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target}"
               BuildableName = "{app}.app"
               BlueprintName = "{app}"
               ReferencedContainer = "container:{app}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target}"
               BuildableName = "{tests}.xctest"
               BlueprintName = "{tests}"
               ReferencedContainer = "container:{app}.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "{app}.app"
            BlueprintName = "{app}"
            ReferencedContainer = "container:{app}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "{app}.app"
            BlueprintName = "{app}"
            ReferencedContainer = "container:{app}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


if __name__ == "__main__":
    generate()
