import toml
import ast
import os
import sys
import re

def get_version_from_setup():
    try:
        if os.path.exists("setup.py"):
            with open("setup.py", "r") as f:
                content = f.read()
            tree = ast.parse(content)
            version_value = None
            for node in tree.body:
                if isinstance(node, ast.Assign):
                    for target in node.targets:
                        if isinstance(target, ast.Name) and target.id == 'version':
                            if isinstance(node.value, ast.Str):
                                version_value = node.value.s
                            elif isinstance(node.value, ast.Constant):
                                version_value = node.value.value
            for node in ast.walk(tree):
                if isinstance(node, ast.Call) and getattr(node.func, 'id', None) == 'setup':
                    for kw in node.keywords:
                        if kw.arg == 'version':
                            if isinstance(kw.value, ast.Str):
                                return kw.value.s
                            elif isinstance(kw.value, ast.Constant):
                                return kw.value.value
                            elif isinstance(kw.value, ast.Name) and kw.value.id == 'version':
                                return version_value
            return version_value
        return None
    except Exception as e:
        print(f"Error parsing setup.py: {e}")
        return None

def get_version_from_toml():
    try:
        if os.path.exists("pyproject.toml"):
            with open("pyproject.toml", "r") as f:
                data = toml.load(f)
            if "tool" in data and "poetry" in data["tool"]:
                return data["tool"]["poetry"].get("version")
            if "project" in data:
                return data["project"].get("version")
        return None
    except Exception as e:
        print(f"Error parsing pyproject.toml: {e}")
        return None

def increment_version(version, increment_type):
    if not version:
        print("No version found to increment.")
        return None
    try:
        major, minor, patch = map(int, version.split('.'))
        if increment_type == "major":
            major += 1
            minor = 0
            patch = 0
        elif increment_type == "minor":
            minor += 1
            patch = 0
        elif increment_type == "patch":
            patch += 1
        else:
            print(f"Invalid increment type: {increment_type}. Use 'major', 'minor', or 'patch'.")
            return None
        return f"{major}.{minor}.{patch}"
    except ValueError as e:
        print(f"Invalid version format: {version}. Expected format: x.y.z")
        return None

def update_setup_version(new_version):
    try:
        if not os.path.exists("setup.py"):
            return False
        with open("setup.py", "r") as f:
            lines = f.readlines()

        with open("setup.py", "r") as f:
            content = f.read()
        tree = ast.parse(content)
        version_line = None
        for node in tree.body:
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name) and target.id == 'version':
                        version_line = node.lineno - 1

        if version_line is None:
            print("Could not find version assignment in setup.py")
            return False

        lines[version_line] = re.sub(
            r"version\s*=\s*['\"]\d+\.\d+\.\d+['\"]",
            f"version = '{new_version}'",
            lines[version_line]
        )
        with open("setup.py", "w") as f:
            f.writelines(lines)
        print(f"Updated setup.py with version: {new_version}")
        return True
    except Exception as e:
        print(f"Error updating setup.py: {e}")
        return False

def update_toml_version(new_version):
    try:
        if not os.path.exists("pyproject.toml"):
            return False
        with open("pyproject.toml", "r") as f:
            lines = f.readlines()

        updated = False
        for i, line in enumerate(lines):
            if re.match(r"^\s*version\s*=\s*['\"]\d+\.\d+\.\d+['\"]", line.strip()):
                lines[i] = re.sub(
                    r"version\s*=\s*['\"]\d+\.\d+\.\d+['\"]",
                    f"version = \"{new_version}\"",
                    line
                )
                updated = True
                break

        if not updated:
            print("Could not find version field in pyproject.toml")
            return False

        with open("pyproject.toml", "w") as f:
            f.writelines(lines)
        print(f"Updated pyproject.toml with version: {new_version}")
        return True
    except Exception as e:
        print(f"Error updating pyproject.toml: {e}")
        return False

def get_project_version_and_update(increment_type):
    current_version = get_version_from_toml()
    if current_version:
        new_version = increment_version(current_version, increment_type)
        if new_version and update_toml_version(new_version):
            return current_version, new_version

    current_version = get_version_from_setup()
    if current_version:
        new_version = increment_version(current_version, increment_type)
        if new_version and update_setup_version(new_version):
            return current_version, new_version

    print("No version found in either pyproject.toml or setup.py")
    return None, None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python script.py [major|minor|patch]")
        sys.exit(1)
    increment_type = sys.argv[1].lower()
    if increment_type not in ["major", "minor", "patch"]:
        print("Argument must be 'major', 'minor', or 'patch'")
        sys.exit(1)
    current_version, new_version = get_project_version_and_update(increment_type)
    if current_version and new_version:
        print(f"Current version: {current_version}")
        print(f"New version: {new_version}")
    else:
        print("Failed to update version.")
        sys.exit(1)
