/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the tests of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers as Helpers
import QtQuick.Controls
import QtQuick.Layouts


Window {
    width: 1280
    height: 720
    visible: true
    title: qsTr("QtQuick3DPhysics character controller test")


    DynamicsWorld {
        id: physicsWorld
        running: true
        forceDebugView: false
        //        enableCCD: true
    }

    View3D {
        anchors.fill: parent
        id: viewport1



    environment: SceneEnvironment {
            clearColor: "#d6dbdf"
            backgroundMode: SceneEnvironment.SkyBox
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
            lightProbe: Texture {
                source: "maps/OpenfootageNET_lowerAustria01-512.hdr"
            }
            skyboxBlurAmount: 0.22
            probeExposure: 5
        }

        StaticRigidBody {
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
        }

        PrincipledMaterial {
            id: stairMaterial
            metalness: 0
            roughness: 0.5
            baseColor: "orange"
            alphaMode: PrincipledMaterial.Opaque
        }
        PrincipledMaterial {
            id: wallMaterial
            metalness: 0
            roughness: 0.5
            baseColor: "gray"
            alphaMode: PrincipledMaterial.Opaque
        }

        Node {
            id: scene

            DirectionalLight {
                eulerRotation.x: -25
                eulerRotation.y: 45
                castsShadow: true
                brightness: 1
                shadowMapQuality: Light.ShadowMapQualityVeryHigh
                shadowFactor: 15
            }

            StaticRigidBody {
                collisionShapes: TriangleMeshShape {
                    id: roomShape
                    meshSource: "meshes/room.mesh"
                }

                Model {
                    id: room
                    source: "meshes/room.mesh"
                    materials: [
                    wallMaterial
                    ]

                }
            }
            StaticRigidBody {
                    x: -600
                    y: 0
                    z: 600
                collisionShapes: TriangleMeshShape {
                    id: stairShape
                    meshSource: "meshes/stairs.mesh"
                }

                Model {
                    id: stairs
                    source: "meshes/stairs.mesh"
                    materials: [
                    stairMaterial
                    ]
                }
            }

            Model {
                id: scenery
                source: "#Cube"
                materials: stairMaterial
                z: -5000
                scale: "10, 0.1, 10"
            }

            Model {
                id: scenery2
                source: "#Cube"
                materials: wallMaterial
                z: -7000
                scale: "10, 0.1, 10"
            }

            Model {
                id: scenery3
                source: "#Cube"
                materials: stairMaterial
                z: -15000
                scale: "10, 0.1, 100"
            }

            Repeater3D {
                model: 10
                StaticRigidBody {
                    id: platform
                    x: 300
                    z: -1300 - 600 * index
                    scale: "2, 0.3, 2"
                    y: 500 + 50 * index
                    collisionShapes: BoxShape {}
                    Model {
                        source: "#Cube"
                        materials: stairMaterial
                    }

                }
            }

            CharacterController {
                id: character
                position: "100, 100, 300"
                eulerRotation.y: wasd.cameraRotation.x

                gravity: flying ? Qt.vector3d(0,0,0) : physicsWorld.gravity
                midAirControl: midAirButton.checked
                property bool physicallyCorrect: correctnessButton.checked
                property bool flying: flyingButton.checked

                property bool grounded: (collisions & CharacterController.Down)
                property bool jumpingAllowed : false

                Timer {
                    id: groundednessTimer
                    // Wile E. Coyote mode: how long after you started to fall
                    // can you still jump? (Only in non-physically-correct mode.)
                    interval: 150
                }
                onGroundedChanged: {
                    groundednessTimer.stop()
                    if (grounded) {
                        // Landing is always immediate, but we don't jump in flying mode
                        jumpingAllowed = !flying
                    } else if (!midAirControl || wasd.jump) {
                        // Jumping is always immediate (no double jumping)
                        jumpingAllowed = false
                    } else {
                        // Walking off a ledge in mid-air mode has a grace period
                        groundednessTimer.restart()
                    }
                }

                property string collisionText: ""
                onCollisionsChanged: {
                    if (collisions === CharacterController.None) {
                        collisionText = " No collisions"
                    } else {
                        collisionText = (collisions & CharacterController.Up ? " Above" : "")
                                     + (collisions & CharacterController.Side ? " Side" : "")
                                     + ((collisions & CharacterController.Down) ? " Below" : "")
                    }
                    console.log("Collision state:" + collisionText + " (" + collisions + ")")
                }

                speed.x: wasd.xFactor * 500;
                speed.z: wasd.zFactor * 500;
                speed.y: ((wasd.jump && jumpingAllowed) ? 500 : 0)
                         + wasd.yFactor * 500
                Behavior on speed.z {
                    PropertyAnimation { duration: 200 }
                }
                Behavior on speed.x {
                    PropertyAnimation { duration: 200 }
                }

                collisionShapes:  CapsuleShape {
                    id: capsuleShape
                }

                Model {
                    // not visible from the camera, but casts a shadow
                    eulerRotation.z: 90
                    geometry: Helpers.CapsuleGeometry {}
                    materials: PrincipledMaterial {
                        baseColor: "red"
                    }
                }

                PerspectiveCamera {
                    id: camera2
                    position: Qt.vector3d(0, capsuleShape.height, 0)
                    eulerRotation.x: wasd.cameraRotation.y
                    clipFar: 10000
                    clipNear: 10
                }
            }
        }
        Wasd {
            id: wasd
            property real sprintFactor: sprintActive ? 3 : 1
            property real xFactor: (moveLeft ? -1 : moveRight ? 1 : 0) * sprintFactor
            property real zFactor: (moveForwards ? -1 : moveBackwards ? 1 : 0) * sprintFactor
            property real yFactor: (character.flying ? (moveUp ? 1 : moveDown ? -1 : 0) : 0) * sprintFactor

            property bool jump: false

            Timer {
                id: preJumpTimer
                interval: 200 // how long before you land can you press jump?
                onTriggered: wasd.jump = false
            }

            function startJump()
            {
                wasd.jump = true
                preJumpTimer.restart()
            }

            Keys.onPressed: (event)=> {
                handleKeyPress(event);
                if (event.key === Qt.Key_Space && !event.isAutoRepeat) {
                    wasd.startJump()
                } else if (event.key === Qt.Key_G) {
                }
            }

            Keys.onReleased: (event) => {
                handleKeyRelease(event)
                if (event.key === Qt.Key_Space) {
                    wasd.jump = false
                }
            }
        }

    } // View3D

    ButtonGroup {
        buttons: column.children
    }

    Column {
        id: column
        RadioButton {
            id: midAirButton
            checked: true
            text: qsTr("Mid-air controls")
            focusPolicy: Qt.NoFocus
        }
        RadioButton {
            id: correctnessButton
            text: qsTr("Physically accurate free fall")
            focusPolicy: Qt.NoFocus
        }
        RadioButton {
            id: flyingButton
            text: qsTr("Flying (no gravity)")
            focusPolicy: Qt.NoFocus
        }

        Button {
            text: "Teleport"
            onClicked: character.teleport(Qt.vector3d(-700, 3000, -6850))
            focusPolicy: Qt.NoFocus
        }
        Text {
            text: "Current position: " + character.position
        }
        Text {
            text: "Collision state:" + character.collisionText
        }
    }
}