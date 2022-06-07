/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
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
import QtQuick3D.Helpers
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: appWindow
    width: 800
    height: 600
    visible: true
    title: qsTr("Qt Quick 3D Physics - Material example")

    DynamicsWorld {}

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            backgroundMode: SceneEnvironment.Color
            clearColor: "#f0f0f0"
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 500, 1500)
            eulerRotation : Qt.vector3d(-20, 0, 0)
            clipFar: 10000
            clipNear: 10
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
            castsShadow: true
            brightness: 1
            shadowFactor: 100
            shadowMapQuality: Light.ShadowMapQualityVeryHigh
        }

        //! [material]
        PhysicsMaterial {
            id: physicsMaterial
            staticFriction: staticFrictionSlider.value
            dynamicFriction: dynamicFrictionSlider.value
            restitution: restitutionSlider.value
        }
        //! [material]

        //! [floor]
        StaticRigidBody {
            eulerRotation: Qt.vector3d(-79, -90, 0)
            scale: Qt.vector3d(20, 30, 100)
            physicsMaterial: physicsMaterial
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                materials: DefaultMaterial {
                    diffuseColor: "green"
                }
            }
        }
        //! [floor]

        //! [box]
        DynamicRigidBody {
            id: box
            physicsMaterial: physicsMaterial
            density: 10
            property var startPosition: Qt.vector3d(700, 300, 0)
            position: startPosition
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "red"
                }
            }
            collisionShapes: BoxShape {}
        }
        //! [box]
    }

    Frame {
        background: Rectangle {
            color: "#c0c0c0"
            border.color: "#202020"
        }
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        ColumnLayout {
            Label {
                text: "Static friction: " + staticFrictionSlider.value.toFixed(2)
            }
            Slider {
                id: staticFrictionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.1
            }
            Label {
                text: "Dynamic friction: " + dynamicFrictionSlider.value.toFixed(2)
            }
            Slider {
                id: dynamicFrictionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.1
            }
            Label {
                text: "Restitution: " + restitutionSlider.value.toFixed(2)
            }
            Slider {
                id: restitutionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.1
            }
            Button {
                id: resetButton
                Layout.alignment: Qt.AlignHCenter
                text: "Reset box"
                onClicked: box.reset(box.startPosition, Qt.vector3d(0, 0, 0))
            }
        }
    }
}