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
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Qt Quick 3D Physics - Scaling test")

    DynamicsWorld {
        id: physicsWorld
        gravity: Qt.vector3d(0, -9.81, 0)
        running: true
        forceDebugView: true

        typicalLength: 1
        typicalSpeed: 10
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#d6dbdf"
            backgroundMode: SceneEnvironment.Color
        }

        Node {
            id: scene

            PerspectiveCamera {
                id: camera1
                position: Qt.vector3d(-2, 1, 5)
                eulerRotation: Qt.vector3d(-20, -20, 0)
                clipFar: 50
                clipNear: 0.01
            }

            DirectionalLight {
                eulerRotation.x: -45
                eulerRotation.y: 45
                castsShadow: true
                brightness: 1
                shadowFactor: 100
            }

            StaticRigidBody {
                id: floor
                position: Qt.vector3d(0, -1, 0)
                eulerRotation: Qt.vector3d(-90, 0, 0)
                collisionShapes: PlaneShape {}
                Model {
                    source: "#Rectangle"
                    scale: Qt.vector3d(5, 5, 0)
                    materials: DefaultMaterial {
                        diffuseColor: "green"
                    }
                    castsShadows: false
                    receivesShadows: true
                }
            }


            Component {
                id: spawnComponent

                DynamicRigidBody {
                    id: thisBody
                    y: 2

                    collisionShapes: SphereShape {
                        id: sphereShape
                        diameter: 1
                    }
                    Model {
                        source: "#Sphere"
                        materials: PrincipledMaterial {
                            baseColor: "orange"
                        }
                        scale: Qt.vector3d(0.01, 0.01, 0.01).times(sphereShape.diameter)
                    }
                    Connections {
                        target: spawner
                        function onKill() {
                            thisBody.destroy()
                        }
                    }
                }
            }

            Timer {
                id: spawner
                interval: 2000
                repeat: true
                running: physicsWorld.running

                onTriggered: {
                    doSpawn()
                }

                function doSpawn() {
                    kill()
                    spawnComponent.createObject(scene)
                }
                signal kill()
            }



            Node {
                id: bodies
                property real sf: scaleSlider.value
                scale: Qt.vector3d(sf, sf, sf)

                DynamicRigidBody {
                    id: box
                    density: 10
                    property var startPos: Qt.vector3d(-1, 1, 0)
                    position: box.startPos

                    property real xf: xSlider.value
                    property real yf: ySlider.value
                    scale: Qt.vector3d(xf, yf, 1)


                    collisionShapes: BoxShape {
                        id: boxShape
                        property real xtent: xtentSlider.value
                        extents: Qt.vector3d(xtent, 1, 1)
                    }
                    Model {
                        source: "#Cube"
                        materials: PrincipledMaterial {
                            baseColor: "yellow"
                        }
                        scale: boxShape.extents.times(0.01)
                    }
                }

                DynamicRigidBody {
                    id: sphere
                    density: 10
                    property var startPos: Qt.vector3d(0, 1, 0)
                    position: sphere.startPos

                    collisionShapes: SphereShape {
                        id: sphereShape
                        diameter: 1
                    }
                    Model {
                        source: "#Sphere"
                        materials: PrincipledMaterial {
                            baseColor: "blue"
                        }
                        scale: Qt.vector3d(0.01, 0.01, 0.01).times(sphereShape.diameter)
                    }
                }

                DynamicRigidBody {
                    id: capsule
                    property var startPos: Qt.vector3d(1, 1, 0)
                    position: capsule.startPos
                    density: 10

                    property real xf: xSlider.value
                    property real yf: ySlider.value
                    scale: Qt.vector3d(xf, yf, yf)

                    collisionShapes: CapsuleShape {
                        id: capsuleShape
                        property real cHeight: heightSlider.value
                        diameter: 1
                        height: cHeight
                    }

                    Model {
                        geometry: CapsuleGeometry {
                            diameter: capsuleShape.diameter
                            height: capsuleShape.height
                        }
                        materials: PrincipledMaterial {
                            baseColor: "red"
                        }
                    }
                }
            } // bodies
        }
    }

 ColumnLayout {

        Label {
            text: "Uniform scale: " + scaleSlider.value
        }
        Slider {
            id: scaleSlider
            focusPolicy: Qt.NoFocus
            from: 0.2
            to: 3
            value: 1
        }
        Label {
            text: "Local x scale: " + xSlider.value
        }
        Slider {
            id: xSlider
            focusPolicy: Qt.NoFocus
            from: 0.2
            to: 3
            value: 1
        }
        Label {
            text: "Local y scale: " + ySlider.value
        }
        Slider {
            id: ySlider
            focusPolicy: Qt.NoFocus
            from: 0.2
            to: 3
            value: 1
        }
        Label {
            text: "Box x extent: " + xtentSlider.value
        }
        Slider {
            id: xtentSlider
            focusPolicy: Qt.NoFocus
            from: 0.2
            to: 5
            value: 1
        }
        Label {
            text: "Capsule height: " + heightSlider.value
        }
        Slider {
            id: heightSlider
            focusPolicy: Qt.NoFocus
            from: 0.2
            to: 5
            value: 1
        }
        Button {
            id: resetButton
            Layout.alignment: Qt.AlignHCenter
            text: "Reset scene"
            onClicked: {
                box.reset(box.startPos, Qt.vector3d(0, 0, 0))
                sphere.reset(sphere.startPos, Qt.vector3d(0, 0, 0))
                capsule.reset(capsule.startPos, Qt.vector3d(0, 0, 0))
            }
        }

    }

}
