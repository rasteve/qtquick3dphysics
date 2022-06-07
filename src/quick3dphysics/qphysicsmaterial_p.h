/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Quick 3D Physics Module.
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

#ifndef QPHYSICSMATERIAL_H
#define QPHYSICSMATERIAL_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <QtQml/QQmlEngine>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QPhysicsMaterial : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float staticFriction READ staticFriction WRITE setStaticFriction NOTIFY
                       staticFrictionChanged)
    Q_PROPERTY(float dynamicFriction READ dynamicFriction WRITE setDynamicFriction NOTIFY
                       dynamicFrictionChanged)
    Q_PROPERTY(float restitution READ restitution WRITE setRestitution NOTIFY restitutionChanged)
    QML_NAMED_ELEMENT(PhysicsMaterial)
public:
    explicit QPhysicsMaterial(QObject *parent = nullptr);

    float staticFriction() const;
    void setStaticFriction(float staticFriction);

    float dynamicFriction() const;
    void setDynamicFriction(float dynamicFriction);

    float restitution() const;
    void setRestitution(float restitution);

    static constexpr float defaultStaticFriction = 0.5f;
    static constexpr float defaultDynamicFriction = 0.5f;
    static constexpr float defaultRestitution = 0.5f;

Q_SIGNALS:
    void staticFrictionChanged();
    void dynamicFrictionChanged();
    void restitutionChanged();

private:
    float m_staticFriction = defaultStaticFriction;
    float m_dynamicFriction = defaultDynamicFriction;
    float m_restitution = defaultRestitution;
};

QT_END_NAMESPACE

#endif // QPHYSICSMATERIAL_H