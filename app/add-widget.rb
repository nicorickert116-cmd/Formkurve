# Fügt dem Capacitor-Projekt die Widget-Erweiterung „FKTimer“ (Live-Aktivität) hinzu und bettet sie in die App ein.
require 'xcodeproj'
proj = Xcodeproj::Project.open('ios/App/App.xcodeproj')
app = proj.targets.find { |t| t.name == 'App' } or abort('App-Target fehlt')
if proj.targets.any? { |t| t.name == 'FKTimer' }
  puts 'FKTimer schon vorhanden'
  exit 0
end
ext = proj.new_target(:app_extension, 'FKTimer', :ios, '16.2', nil, :swift)
# Foundation wird von Swift automatisch gelinkt; der feste SDK-Pfad, den xcodeproj einträgt, passt nicht zu jeder Xcode-Version
ext.frameworks_build_phase.files.to_a.each { |bf| ref = bf.file_ref; bf.remove_from_project; ref.remove_from_project if ref && ref.build_files.empty? }
grp = proj.main_group.new_group('FKTimer', 'FKTimer')
ext.add_file_references(%w[FKAttributes.swift FKTimerWidget.swift].map { |f| grp.new_reference(f) })
ext.add_resources([grp.new_reference('BarlowCondensed-ExtraBold.ttf')])
grp.new_reference('Info.plist')
base = app.build_configurations.first.build_settings
bundle = base['PRODUCT_BUNDLE_IDENTIFIER'] || 'io.github.nicorickert116.formkurve'
ext.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = bundle + '.timer'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'FKTimer/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['MARKETING_VERSION'] = base['MARKETING_VERSION'] || '1.0'
  s['CURRENT_PROJECT_VERSION'] = base['CURRENT_PROJECT_VERSION'] || '1'
  s['CODE_SIGN_STYLE'] = 'Automatic'
end
app.add_dependency(ext)
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(ext.product_reference, true)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
proj.save
puts "FKTimer hinzugefügt (#{bundle}.timer)"
