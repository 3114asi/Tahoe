set(forceblur_SOURCES
    blur.cpp
    blur.qrc
    main.cpp
)

kconfig_add_kcfg_files(forceblur_SOURCES
    blurconfig.kcfgc
)

add_library(forceblur MODULE ${forceblur_SOURCES})
set_target_properties(forceblur PROPERTIES OUTPUT_NAME "forceblur")
target_link_libraries(forceblur PRIVATE
    KWin::kwin
    KF6::ConfigGui
    KDecoration3::KDecoration
    XCB::XCB
    epoxy::epoxy
)
install(TARGETS forceblur DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/plugins)
