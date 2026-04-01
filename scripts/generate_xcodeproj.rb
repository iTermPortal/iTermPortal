#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'xcodeproj'

ROOT = Pathname.new(__dir__).parent.expand_path
PROJECT_PATH = ROOT + 'iTermPortal.xcodeproj'
PROJECT_NAME = 'iTermPortal'

APP_SOURCES = %w[
  Sources/iTermPortal/AppDelegate.swift
  Sources/iTermPortal/AboutWindowController.swift
  Sources/iTermPortal/OnboardingWindowController.swift
  Sources/iTermPortal/PreferenceMigration.swift
  Sources/iTermPortal/main.swift
  Sources/Shared/Preferences.swift
  Sources/Shared/StringExtensions.swift
  Sources/Shared/TerminalLauncher.swift
].freeze

EXTENSION_SOURCES = %w[
  Sources/iTermPortalSync/FinderSync.swift
  Sources/Shared/Preferences.swift
  Sources/Shared/StringExtensions.swift
  Sources/Shared/TerminalLauncher.swift
].freeze

TEST_SOURCES = %w[
  Tests/iTermPortalTests/iTermPortalTests.swift
].freeze

TEST_SUPPORT_SOURCES = %w[
  Sources/iTermPortal/PreferenceMigration.swift
  Sources/Shared/Preferences.swift
  Sources/Shared/StringExtensions.swift
  Sources/Shared/TerminalLauncher.swift
].freeze

APP_RESOURCES = %w[
  Resources/iTermPortal/Assets.xcassets
].freeze

EXTENSION_RESOURCES = %w[
  Resources/iTermPortalSync/Assets.xcassets
].freeze

APP_FRAMEWORKS = %w[
  FinderSync.framework
  ServiceManagement.framework
].freeze

EXTENSION_FRAMEWORKS = %w[
  FinderSync.framework
].freeze

VERSION = begin
  ssmver = (ROOT + 'ssmver.toml').read
  ssmver[/^version\s*=\s*"([^"]+)"/, 1] || '1.0'
end

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
project.root_object.attributes['LastSwiftUpdateCheck'] = '1640'
project.root_object.attributes['LastUpgradeCheck'] = '1640'
project.root_object.development_region = 'en'
project.root_object.known_regions = %w[en Base]

app_target = project.new_target(:application, PROJECT_NAME, :osx, '12.0', nil, :swift)
extension_target = project.new_target(:app_extension, 'iTermPortalSync', :osx, '12.0', nil, :swift)
test_target = project.new_target(:unit_test_bundle, 'iTermPortalTests', :osx, '12.0', nil, :swift)

[project, app_target, extension_target, test_target].each do |object|
  object.add_build_configuration('AppStore', :release)
  object.add_build_configuration('DirectInstall', :release)
end

project.root_object.build_configuration_list.default_configuration_name = 'Release'
[app_target, extension_target, test_target].each do |target|
  target.build_configuration_list.default_configuration_name = 'Release'
end

project.root_object.attributes['TargetAttributes'] = {
  app_target.uuid => {
    'CreatedOnToolsVersion' => '16.4',
    'ProvisioningStyle' => 'Automatic',
    'SystemCapabilities' => {
      'com.apple.AppSandbox' => { 'enabled' => 1 },
      'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 }
    }
  },
  extension_target.uuid => {
    'CreatedOnToolsVersion' => '16.4',
    'ProvisioningStyle' => 'Automatic',
    'SystemCapabilities' => {
      'com.apple.AppSandbox' => { 'enabled' => 1 },
      'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 },
      'com.apple.FinderSync' => { 'enabled' => 1 }
    }
  },
  test_target.uuid => {
    'CreatedOnToolsVersion' => '16.4',
    'ProvisioningStyle' => 'Automatic'
  }
}

def ensure_file_reference(project, relative_path)
  existing = project.files.find { |file| file.path == relative_path }
  return existing if existing

  project.main_group.new_file(relative_path)
end

APP_SOURCES.each do |path|
  app_target.source_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

EXTENSION_SOURCES.each do |path|
  extension_target.source_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

TEST_SOURCES.each do |path|
  test_target.source_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

TEST_SUPPORT_SOURCES.each do |path|
  test_target.source_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

APP_RESOURCES.each do |path|
  app_target.resources_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

EXTENSION_RESOURCES.each do |path|
  extension_target.resources_build_phase.add_file_reference(ensure_file_reference(project, path), true)
end

[
  'Resources/iTermPortal/Info.plist',
  'Resources/iTermPortalSync/Info.plist',
  'Entitlements/iTermPortal-AppStore.entitlements',
  'Entitlements/iTermPortal-DirectInstall.entitlements',
  'Entitlements/iTermPortalSync-AppStore.entitlements',
  'Entitlements/iTermPortalSync-DirectInstall.entitlements',
  'scripts/generate_icons.sh'
].each do |path|
  ensure_file_reference(project, path)
end

frameworks_group = project.frameworks_group

APP_FRAMEWORKS.each do |framework|
  ref = frameworks_group.new_file("/System/Library/Frameworks/#{framework}")
  app_target.frameworks_build_phase.add_file_reference(ref)
end

EXTENSION_FRAMEWORKS.each do |framework|
  ref = frameworks_group.files.find { |file| file.path == "/System/Library/Frameworks/#{framework}" } ||
    frameworks_group.new_file("/System/Library/Frameworks/#{framework}")
  extension_target.frameworks_build_phase.add_file_reference(ref)
end

app_target.add_dependency(extension_target)
embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.symbol_dst_subfolder_spec = :plug_ins
build_file = embed_phase.add_file_reference(extension_target.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy] }

base_project_settings = {
  'CLANG_ENABLE_OBJC_ARC' => 'YES',
  'CURRENT_PROJECT_VERSION' => '1',
  'DEVELOPMENT_TEAM' => '',
  'ENABLE_HARDENED_RUNTIME' => 'YES',
  'MACOSX_DEPLOYMENT_TARGET' => '12.0',
  'MARKETING_VERSION' => VERSION,
  'SWIFT_VERSION' => '5.9'
}

project.build_configurations.each do |config|
  config.build_settings.merge!(base_project_settings)
end

app_target.build_configurations.each do |config|
  automatic_local_signing = %w[Debug Release].include?(config.name)
  config.build_settings.merge!(
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => '',
    'CODE_SIGN_ENTITLEMENTS' => config.name == 'AppStore' ? 'Entitlements/iTermPortal-AppStore.entitlements' : 'Entitlements/iTermPortal-DirectInstall.entitlements',
    'CODE_SIGN_INJECT_BASE_ENTITLEMENTS' => automatic_local_signing ? 'YES' : 'NO',
    'CODE_SIGN_STYLE' => automatic_local_signing ? 'Automatic' : 'Manual',
    'ENABLE_APP_SANDBOX' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'INFOPLIST_FILE' => 'Resources/iTermPortal/Info.plist',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.hjoncour.fPortal',
    'PRODUCT_NAME' => PROJECT_NAME,
    'SWIFT_EMIT_LOC_STRINGS' => 'NO'
  )
end

extension_target.build_configurations.each do |config|
  automatic_local_signing = %w[Debug Release].include?(config.name)
  config.build_settings.merge!(
    'CODE_SIGN_ENTITLEMENTS' => config.name == 'AppStore' ? 'Entitlements/iTermPortalSync-AppStore.entitlements' : 'Entitlements/iTermPortalSync-DirectInstall.entitlements',
    'CODE_SIGN_INJECT_BASE_ENTITLEMENTS' => automatic_local_signing ? 'YES' : 'NO',
    'CODE_SIGN_STYLE' => automatic_local_signing ? 'Automatic' : 'Manual',
    'ENABLE_APP_SANDBOX' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'INFOPLIST_FILE' => 'Resources/iTermPortalSync/Info.plist',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.hjoncour.fPortal.FinderExtension',
    'PRODUCT_NAME' => 'iTermPortalSync',
    'SKIP_INSTALL' => 'YES',
    'SWIFT_EMIT_LOC_STRINGS' => 'NO'
  )
end

test_target.build_configurations.each do |config|
  config.build_settings.merge!(
    'BUNDLE_LOADER' => '',
    'CODE_SIGN_STYLE' => 'Automatic',
    'ENABLE_TESTABILITY' => config.name == 'Debug' ? 'YES' : 'NO',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'iTermPortalTests',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.hjoncour.fPortal.tests',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_EMIT_LOC_STRINGS' => 'NO',
    'TEST_HOST' => ''
  )
end

project.recreate_user_schemes(true)
Xcodeproj::XCScheme.share_scheme(PROJECT_PATH, PROJECT_NAME)
Xcodeproj::XCScheme.share_scheme(PROJECT_PATH, 'iTermPortalTests')
FileUtils.rm_rf(PROJECT_PATH + 'xcuserdata')

project.sort
project.save

puts "Generated #{PROJECT_PATH}"
