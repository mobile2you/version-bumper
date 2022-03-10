#!/bin/bash
set -ex

function validate_build_version {
  local version=$1
  local SEMVER_REGEX="^([0-9]*)\\.([0-9]*)\\.([0-9]*)$"
  if [[ "$version" =~ $SEMVER_REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      eval "$2=(\"${major#0}\" \"${minor#0}\" \"${patch#0}\")"
    else
      echo "$version"
    fi
  else
    error "version $version does not match the scheme 'X.Y.Z'. See help for more information."
  fi
}

function validate_compilation_version {
  local version=$1
  local SEMVER_REGEX="^([0-9]{2})([0-9]{2})([0-9]{3})([0-9]{2})$"
  if [[ "$version" =~ $SEMVER_REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      local build=${BASH_REMATCH[4]}
      eval "$2=(\"${major#0}\" \"${minor#0}\" \"${patch#0}\" \"${build#0}\")"
    else
      echo "$version"
    fi
  else
    error "version $version does not match the scheme 'X.Y.Z'. See help for more information."
  fi
}

buildNumber=$(xcodebuild -target $target -showBuildSettings | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION =')
compilationNumber=$(xcodebuild -target $target -showBuildSettings | grep CURRENT_PROJECT_VERSION | tr -d 'CURRENT_PROJECT_VERSION =')

echo "Build Number: $buildNumber"
echo "Compilation Number: $compilationNumber"

validate_build_version $buildNumber parsedBuildVersion

buildMajor="${parsedBuildVersion[0]}"
buildMinor="${parsedBuildVersion[1]}"
buildPatch="${parsedBuildVersion[2]}"

echo "Major: $buildMajor / Minor: $buildMinor / Patch: $buildPatch"

validate_compilation_version $compilationNumber parsedCompilationVersion

compilationMajor="${parsedCompilationVersion[0]}"
compilationMinor="${parsedCompilationVersion[1]}"
compilationPatch="${parsedCompilationVersion[2]}"
compilationBuild="${parsedCompilationVersion[3]}"

echo "Major: $compilationMajor / Minor: $compilationMinor / Patch: $compilationPatch / Build: $compilationBuild"

newBuildMajor=$((${buildMajor#0} + majorIncreaseValue))
newBuildMinor=$((${buildMinor#0} + minorIncreaseValue))
newBuildPatch=$((${buildPatch#0} + patchIncreaseValue))

newBuildNumber="$newBuildMajor.$newBuildMinor.$newBuildPatch"
echo "newBuildNumber: $newBuildNumber"

newCompilationMajor=$(printf "%02d" $((${compilationMajor#0} + majorIncreaseValue)))
newCompilationMinor=$(printf "%02d" $((${compilationMinor#0} + minorIncreaseValue)))
newCompilationPatch=$(printf "%03d" $((${compilationPatch#0} + patchIncreaseValue)))
newCompilationBuild=$(printf "%02d" $((${compilationBuild#0} + buildIncreaseValue)))

newCompilationNumber="$newCompilationMajor$newCompilationMinor$newCompilationPatch$newCompilationBuild"
echo "newCompilationNumber: $newCompilationNumber"

sed -i "" "s/MARKETING_VERSION = $buildNumber/MARKETING_VERSION = $newBuildNumber/g" Mobile2You.xcodeproj/project.pbxproj
sed -i "" "s/CURRENT_PROJECT_VERSION = $compilationNumber/CURRENT_PROJECT_VERSION = $newCompilationNumber/g" Mobile2You.xcodeproj/project.pbxproj

git checkout -b release/${newBuildNumber}${buildTriggerTag}
git add --all
git commit -m "chore($versionBumpIssue): (Version bump $newBuildNumber)"
git tag "$newBuildNumber$buildTriggerTag"
git push --tag $version_tag --set-upstream origin release/${newBuildNumber}${buildTriggerTag}

exit 0
