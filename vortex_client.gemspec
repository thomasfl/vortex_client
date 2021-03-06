# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vortex_client}
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas Flemming"]
  s.date = %q{2011-08-02}
  s.default_executable = %q{vrtx-sync}
  s.description = %q{Utility for managing content on Vortex web content management system through webdav}
  s.email = %q{thomas.flemming@usit.uio.no}
  s.executables = ["vrtx-sync"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/vrtx-sync",
     "examples/README.rdoc",
     "examples/change_folder_type.rb",
     "examples/create_collection.rb",
     "examples/create_personpresentations.rb",
     "examples/dice.gif",
     "examples/disable_right_column.rb",
     "examples/download_and_upload_pdf.rb",
     "examples/import_static_site.rb",
     "examples/ldap_util.rb",
     "examples/make_links_relative.rb",
     "examples/no_right_margin.rb",
     "examples/person_presentation.rb",
     "examples/propfind_proppatch.rb",
     "examples/publish_article.rb",
     "examples/publish_event.rb",
     "examples/publish_json.rb",
     "examples/scrape_hero_publications.rb",
     "examples/scrape_holocaust.rb",
     "examples/scrape_holocaust_related_links.rb",
     "examples/scrape_vortex_search.rb",
     "examples/search_replace_documents.rb",
     "examples/sitemap.rb",
     "examples/unpublish.rb",
     "examples/upload_image.rb",
     "lib/vortex_client.rb",
     "lib/vortex_client/item_extensions.rb",
     "lib/vortex_client/person.rb",
     "lib/vortex_client/string_utils.rb",
     "lib/vortex_client/utilities.rb",
     "test/helper.rb",
     "test/test_acl.rb",
     "test/test_date_conversion.rb",
     "test/test_json_publish.rb",
     "test/test_vortex_article_publish.rb",
     "test/test_vortex_client.rb",
     "test/test_vortex_collection.rb",
     "test/test_vortex_event.rb",
     "test/test_vortex_person.rb",
     "test/test_vortex_pic.rb",
     "test/test_vortex_tags.rb",
     "test/test_vortex_utils.rb"
  ]
  s.homepage = %q{http://github.com/thomasfl/vortex_client}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Vortex CMS client}
  s.test_files = [
    "test/helper.rb",
     "test/test_acl.rb",
     "test/test_date_conversion.rb",
     "test/test_json_publish.rb",
     "test/test_vortex_article_publish.rb",
     "test/test_vortex_client.rb",
     "test/test_vortex_collection.rb",
     "test/test_vortex_event.rb",
     "test/test_vortex_person.rb",
     "test/test_vortex_pic.rb",
     "test/test_vortex_tags.rb",
     "test/test_vortex_utils.rb",
     "examples/change_folder_type.rb",
     "examples/create_collection.rb",
     "examples/create_personpresentations.rb",
     "examples/disable_right_column.rb",
     "examples/download_and_upload_pdf.rb",
     "examples/import_static_site.rb",
     "examples/ldap_util.rb",
     "examples/make_links_relative.rb",
     "examples/no_right_margin.rb",
     "examples/person_presentation.rb",
     "examples/propfind_proppatch.rb",
     "examples/publish_article.rb",
     "examples/publish_event.rb",
     "examples/publish_json.rb",
     "examples/scrape_hero_publications.rb",
     "examples/scrape_holocaust.rb",
     "examples/scrape_holocaust_related_links.rb",
     "examples/scrape_vortex_search.rb",
     "examples/search_replace_documents.rb",
     "examples/sitemap.rb",
     "examples/unpublish.rb",
     "examples/upload_image.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<net_dav>, [">= 0.5.0"])
      s.add_runtime_dependency(%q<highline>, [">= 1.5.1"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<net_dav>, [">= 0.5.0"])
      s.add_dependency(%q<highline>, [">= 1.5.1"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<net_dav>, [">= 0.5.0"])
    s.add_dependency(%q<highline>, [">= 1.5.1"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end

