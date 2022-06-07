/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the test suite of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: appWindow
    width: 1280
    height: 720
    visible: true
    title: qsTr("PhysX Friction Test")

    DynamicsWorld {
        id: physicsWorld
        gravity: Qt.vector3d(0, -9.81, 0)
        running: false
        typicalLength: toleranceLengthSlider.value
        typicalSpeed: toleranceSpeedSlider.value
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
        }

        focus: true
        Keys.onSpacePressed: {
            console.log("toggle physics")
            physicsWorld.running = !physicsWorld.running
        }

        Node {
            id: scene1
            PerspectiveCamera {
                id: camera1
                z: 5
                x: -2
                y: 1
                eulerRotation : Qt.vector3d(-20, -20, 0)
                clipFar: 50
                clipNear: 0.01
            }

            DirectionalLight {
                eulerRotation: Qt.vector3d(-45, 45, 0)
                castsShadow: true
                brightness: 1
                shadowMapQuality: Light.ShadowMapQualityVeryHigh
            }


            PhysicsMaterial {
                id: testMaterial
                staticFriction: staticFrictionSlider.value
                dynamicFriction: dynamicFrictionSlider.value
                restitution: restitutionSlider.value
            }

            StaticRigidBody {
                id: floor
                eulerRotation: Qt.vector3d(-79, -90, 0)
                scale: Qt.vector3d(0.3, 0.3, 0.3)
                physicsMaterial: testMaterial
                collisionShapes: PlaneShape {
                    enableDebugView: true
                }
                Model {
                    source: "#Rectangle"
                    materials: DefaultMaterial {
                        diffuseColor: "green"
                    }
                }
            }

            DynamicRigidBody {
                id: box
                physicsMaterial: testMaterial
                mass: 50

                function init() {
                    console.log("Reinit pos")
                    box.reset(Qt.vector3d(0, 5.9, 0), Qt.vector3d(0, 0, 0));
                }

                y: 0.9
                Model {
                    source: "#Cube"
                    materials: PrincipledMaterial {
                        baseColor: "red"
                    }
                    scale: Qt.vector3d(0.01, 0.01, 0.01)
                }
                collisionShapes: BoxShape {
                    extents: Qt.vector3d(1, 1, 1)
                    enableDebugView: true
                }
            }
        } // scene

    } // View3D

    WasdController {
        keysEnabled: true
        property bool controllingUnit: false
        controlledObject: camera1
        speed: 0.02

        Keys.onPressed: (event)=> {
            if (keysEnabled) handleKeyPress(event);
            if (event.key === Qt.Key_Space) {
                if (box.isKinematic) {
                    console.log("set box to moving")
                    box.isKinematic = false
                    physicsWorld.running = true
                } else {
                    physicsWorld.running = !physicsWorld.running
                    console.log("Set physics to", physicsWorld.running)
                }
            } else if (event.key === Qt.Key_J) {
                floor.eulerRotation.z++
                console.log("Floor rotation", floor.eulerRotation.z)
            } else if (event.key === Qt.Key_K) {
                floor.eulerRotation.z--
                console.log("Floor rotation", floor.eulerRotation.z)
            } else if (event.key === Qt.Key_I) {
                box.init()
            }
        }
        Keys.onReleased: (event)=> { if (keysEnabled) handleKeyRelease(event) }
    }

    ColumnLayout {

        Label {
            text: "Static friction: " + staticFrictionSlider.value
        }
        Slider {
            id: staticFrictionSlider
            focusPolicy: Qt.NoFocus
            from: 0
            to: 1
            value: 0.1
        }

        Label {
            text: "Dynamic friction: " + dynamicFrictionSlider.value
        }
        Slider {
            id: dynamicFrictionSlider
            focusPolicy: Qt.NoFocus
            from: 0
            to: 1
            value: 0.1
        }

        Label {
            text: "Restitution: " + restitutionSlider.value
        }
        Slider {
            id: restitutionSlider
            focusPolicy: Qt.NoFocus
            from: 0
            to: 1
            value: 0.1
        }

        Label {
            text: "Tolerance length: " + toleranceLengthSlider.value
        }
        Slider {
            id: toleranceLengthSlider
            focusPolicy: Qt.NoFocus
            from: 0
            to: 10
            value: 1
        }

        Label {
            text: "Tolerance speed: " + toleranceSpeedSlider.value
        }
        Slider {
            id: toleranceSpeedSlider
            focusPolicy: Qt.NoFocus
            from: 0
            to: 10
            value: 1
        }
    }
}