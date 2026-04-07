set(EXE_NAME ${PROJECT_NAME})

find_package(Qt6 COMPONENTS Quick REQUIRED)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(${EXE_NAME}
    main.cpp
)

qt_add_resources(${EXE_NAME} "qml_resources"
    PREFIX "/"
    FILES
        qml/Main.qml
)

set_target_properties(${EXE_NAME} PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)
if(APPLE)
    set_target_properties(${EXE_NAME} PROPERTIES MACOSX_BUNDLE TRUE)
endif()
if(WIN32)
    set_target_properties(${EXE_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)
endif()
if(ANDROID)
    set_target_properties(${EXE_NAME} PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )
endif()

target_link_libraries(${EXE_NAME}
    PRIVATE Qt6::Quick
)

install(TARGETS ${EXE_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)