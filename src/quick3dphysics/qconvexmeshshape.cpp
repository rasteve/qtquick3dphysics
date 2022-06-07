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

#include "qconvexmeshshape_p.h"

#include <QFile>
#include <QFileInfo>
#include <QtQuick3D/QQuick3DGeometry>
#include <extensions/PxExtensionsAPI.h>

#include "foundation/PxVec3.h"
#include "cooking/PxConvexMeshDesc.h"
#include "extensions/PxDefaultStreams.h"

#include <QtQml/qqml.h>
#include <QtQml/QQmlFile>
#include <QtQml/qqmlcontext.h>

#include <QtQuick3DUtils/private/qssgmesh_p.h>
#include "qdynamicsworld_p.h"
#include "qphysicsmeshutils_p_p.h"
#include "qphysicsutils_p.h"

QT_BEGIN_NAMESPACE

physx::PxConvexMesh *QQuick3DPhysicsMesh::convexMesh()
{
    if (!m_convexMesh) {

        //### hacky accessors
        //            physx::PxCooking *theCooking = QDynamicsWorld::getCooking();
        physx::PxPhysics *thePhysics = QDynamicsWorld::getPhysics();
        if (thePhysics == nullptr)
            return nullptr;

        static QString meshCachePath = qEnvironmentVariable("QT_PHYSX_CACHE_PATH");
        static bool cachingEnabled = !meshCachePath.isEmpty();

        QString fn = cachingEnabled ? QString::fromUtf8("%1/%2.mesh_physx")
                                              .arg(meshCachePath, QFileInfo(m_meshPath).fileName())
                                    : QString::fromUtf8("%1.mesh_physx").arg(m_meshPath);

        QFile f(fn);

        if (f.open(QIODevice::ReadOnly)) {
            auto size = f.size();
            auto *data = f.map(0, size);
            physx::PxDefaultMemoryInputData input(data, size);
            m_convexMesh = thePhysics->createConvexMesh(input);
            qCDebug(lcQuick3dPhysics) << "Read convex mesh" << m_convexMesh << "from file" << fn;
        }

        if (!m_convexMesh) {
            loadSsgMesh();
            if (!m_ssgMesh.isValid())
                return nullptr;

            physx::PxDefaultMemoryOutputStream buf;
            physx::PxConvexMeshCookingResult::Enum result;
            int vStride = m_ssgMesh.vertexBuffer().stride;
            int vCount = m_ssgMesh.vertexBuffer().data.size() / vStride;
            const auto *vd = m_ssgMesh.vertexBuffer().data.constData();

            qCDebug(lcQuick3dPhysics) << "prepare cooking" << vCount << "verts";

            QVector<physx::PxVec3> verts;

            for (int i = 0; i < vCount; ++i) {
                auto *vp = reinterpret_cast<const QVector3D *>(vd + vStride * i + m_posOffset);
                verts << physx::PxVec3 { vp->x(), vp->y(), vp->z() };
            }

            const auto *convexVerts = verts.constData();

            physx::PxConvexMeshDesc convexDesc;
            convexDesc.points.count = vCount;
            convexDesc.points.stride = sizeof(physx::PxVec3);
            convexDesc.points.data = convexVerts;
            convexDesc.flags = physx::PxConvexFlag::eCOMPUTE_CONVEX;

            if (QDynamicsWorld::getCooking()->cookConvexMesh(convexDesc, buf, &result)) {
                auto size = buf.getSize();
                auto *data = buf.getData();

                if (cachingEnabled) {
                    if (f.open(QIODevice::WriteOnly)) {
                        f.write(reinterpret_cast<char *>(data), size);
                        f.close();
                        qCDebug(lcQuick3dPhysics) << "Wrote" << size << "bytes to" << f.fileName();
                    } else {
                        qCWarning(lcQuick3dPhysics)
                                << "Could not open" << f.fileName() << "for writing.";
                    }
                }

                physx::PxDefaultMemoryInputData input(data, size);
                m_convexMesh = thePhysics->createConvexMesh(input);

                qCDebug(lcQuick3dPhysics)
                        << "Created convex mesh" << m_convexMesh << "for mesh" << this;
            } else {
                qCWarning(lcQuick3dPhysics) << "Could not create convex mesh from" << m_meshPath;
            }
        }
    }

    return m_convexMesh;
}

physx::PxTriangleMesh *QQuick3DPhysicsMesh::triangleMesh()
{
    physx::PxPhysics *thePhysics = QDynamicsWorld::getPhysics();
    if (thePhysics == nullptr)
        return nullptr;

    static QString meshCachePath = qEnvironmentVariable("QT_PHYSX_CACHE_PATH");
    static bool cachingEnabled = !meshCachePath.isEmpty();

    QString fn = cachingEnabled ? QString::fromUtf8("%1/%2.triangle_physx")
                                          .arg(meshCachePath, QFileInfo(m_meshPath).fileName())
                                : QString::fromUtf8("%1.triangle_physx").arg(m_meshPath);
    QFile f(fn);

    if (f.open(QIODevice::ReadOnly)) {
        auto size = f.size();
        auto *data = f.map(0, size);
        physx::PxDefaultMemoryInputData input(data, size);
        m_triangleMesh = thePhysics->createTriangleMesh(input);
        qCDebug(lcQuick3dPhysics) << "Read triangle mesh" << m_triangleMesh << "from file" << fn;
    }

    if (!m_triangleMesh) {
        loadSsgMesh();
        if (!m_ssgMesh.isValid())
            return nullptr;

        physx::PxDefaultMemoryOutputStream buf;
        physx::PxTriangleMeshCookingResult::Enum result;
        const int vStride = m_ssgMesh.vertexBuffer().stride;
        const int vCount = m_ssgMesh.vertexBuffer().data.size() / vStride;
        const auto *vd = m_ssgMesh.vertexBuffer().data.constData();

        const int iStride = m_ssgMesh.indexBuffer().componentType
                        == QSSGMesh::Mesh::ComponentType::UnsignedInt16
                ? 2
                : 4;
        const int iCount = m_ssgMesh.indexBuffer().data.size() / iStride;

        qCDebug(lcQuick3dPhysics) << "prepare cooking" << vCount << "verts" << iCount << "idxs";

        physx::PxTriangleMeshDesc triangleDesc;
        triangleDesc.points.count = vCount;
        triangleDesc.points.stride = vStride;
        triangleDesc.points.data = vd + m_posOffset;

        triangleDesc.flags = {}; //??? physx::PxMeshFlag::eFLIPNORMALS or
                                 // physx::PxMeshFlag::e16_BIT_INDICES
        triangleDesc.triangles.count = iCount / 3;
        triangleDesc.triangles.stride = iStride * 3;
        triangleDesc.triangles.data = m_ssgMesh.indexBuffer().data.constData();

        if (QDynamicsWorld::getCooking()->cookTriangleMesh(triangleDesc, buf, &result)) {
            auto size = buf.getSize();
            auto *data = buf.getData();

            if (cachingEnabled) {
                if (f.open(QIODevice::WriteOnly)) {
                    f.write(reinterpret_cast<char *>(data), size);
                    f.close();
                    qCDebug(lcQuick3dPhysics) << "Wrote" << size << "bytes to" << f.fileName();
                } else {
                    qCWarning(lcQuick3dPhysics)
                            << "Could not open" << f.fileName() << "for writing.";
                }
            }

            physx::PxDefaultMemoryInputData input(data, size);
            m_triangleMesh = thePhysics->createTriangleMesh(input);

            qCDebug(lcQuick3dPhysics)
                    << "Created triangle mesh" << m_triangleMesh << "for mesh" << this;
        } else {
            qCWarning(lcQuick3dPhysics) << "Could not create triangle mesh from" << m_meshPath;
        }
    }

    return m_triangleMesh;
}

void QQuick3DPhysicsMesh::loadSsgMesh()
{
    if (m_ssgMesh.isValid())
        return;

    static const char *compTypes[] = { "Null",  "UnsignedInt8",  "Int8",    "UnsignedInt16",
                                       "Int16", "UnsignedInt32", "Int32",   "UnsignedInt64",
                                       "Int64", "Float16",       "Float32", "Float64" };

    QFileInfo fileInfo = QFileInfo(m_meshPath);
    if (fileInfo.exists()) {
        QFile file(fileInfo.absoluteFilePath());
        if (file.open(QFile::ReadOnly))
            m_ssgMesh = QSSGMesh::Mesh::loadMesh(&file);
    }
    qCDebug(lcQuick3dPhysics) << "Loaded SSG mesh from" << m_meshPath << m_ssgMesh.isValid()
                              << "draw" << int(m_ssgMesh.drawMode()) << "wind"
                              << int(m_ssgMesh.winding()) << "subs" << m_ssgMesh.subsets().count()
                              << "attrs" << m_ssgMesh.vertexBuffer().entries.count()
                              << m_ssgMesh.vertexBuffer().data.size() << "stride"
                              << m_ssgMesh.vertexBuffer().stride << "verts"
                              << m_ssgMesh.vertexBuffer().data.size()
                    / m_ssgMesh.vertexBuffer().stride;

    for (auto &v : m_ssgMesh.vertexBuffer().entries) {
        qCDebug(lcQuick3dPhysics) << "  attr" << v.name << compTypes[int(v.componentType)] << "cc"
                                  << v.componentCount << "offs" << v.offset;
        Q_ASSERT(v.componentType == QSSGMesh::Mesh::ComponentType::Float32);
        if (v.name == "attr_pos")
            m_posOffset = v.offset;
    }

    if (m_ssgMesh.isValid()) {
        auto sub = m_ssgMesh.subsets().first();
        qCDebug(lcQuick3dPhysics) << "..." << sub.name << "count" << sub.count << "bounds"
                                  << sub.bounds.min << sub.bounds.max << "offset" << sub.offset;
    }

#if 0 // EXTRA_DEBUG

    int iStride = m_ssgMesh.indexBuffer().componentType == QSSGMesh::Mesh::ComponentType::UnsignedInt16 ? 2 : 4;
    int vStride = m_ssgMesh.vertexBuffer().stride;
    qDebug() << "IDX" << compTypes[int(m_ssgMesh.indexBuffer().componentType)] << m_ssgMesh.indexBuffer().data.size() / iStride;
    const auto ib = m_ssgMesh.indexBuffer().data;
    const auto vb = m_ssgMesh.vertexBuffer().data;

    auto getPoint = [&vb, vStride, this](int idx) -> QVector3D {
        auto *vp = vb.constData() + vStride * idx + m_posOffset;
        return *reinterpret_cast<const QVector3D *>(vp);
        return {};
    };

    if (iStride == 2) {

    } else {
        auto *ip = reinterpret_cast<const uint32_t *>(ib.data());
        int n = ib.size() / iStride;
        for (int i = 0; i < qMin(50,n); i += 3) {

            qDebug() << "    " << ip [i] << ip[i+1] << ip[i+2] << " --- "
                     << getPoint(ip[i]) << getPoint(ip[i+1]) << getPoint(ip[i+2]);
        }
    }
#endif
    if (!m_ssgMesh.isValid())
        qCWarning(lcQuick3dPhysics) << "Could not read mesh from" << m_meshPath;
}

QQuick3DPhysicsMesh *QQuick3DPhysicsMeshManager::getMesh(const QUrl &source,
                                                         const QObject *contextObject)
{
    const QQmlContext *context = qmlContext(contextObject);
    const auto resolvedUrl = context ? context->resolvedUrl(source) : source;
    const auto qmlSource = QQmlFile::urlToLocalFileOrQrc(resolvedUrl);
    auto *mesh = meshHash.value(qmlSource);
    if (!mesh) {
        mesh = new QQuick3DPhysicsMesh(qmlSource);
        meshHash[qmlSource] = mesh;
    }
    mesh->ref();
    return mesh;
}

void QQuick3DPhysicsMeshManager::releaseMesh(QQuick3DPhysicsMesh *mesh)
{
    if (mesh->deref() == 0) {
        qCDebug(lcQuick3dPhysics()) << "deleting mesh" << mesh;
        erase_if(meshHash, [mesh](std::pair<const QString &, QQuick3DPhysicsMesh *&> h) {
            return h.second == mesh;
        });
        delete mesh;
    }
}

QHash<QString, QQuick3DPhysicsMesh *> QQuick3DPhysicsMeshManager::meshHash;

/*!
    \qmltype ConvexMeshShape
    \inherits CollisionShape
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Defines a convex shape based on a mesh.

    This type defines a convex shape based on a mesh.

*/

/*!
  \qmlproperty url ConvexMeshShape::meshSource
  This property defines the location of the mesh file used to define the shape. If the
  mesh is not convex, the convex hull of the mesh will be used.
*/

QConvexMeshShape::QConvexMeshShape() = default;

QConvexMeshShape::~QConvexMeshShape()
{
    delete m_meshGeometry;
    if (m_mesh)
        QQuick3DPhysicsMeshManager::releaseMesh(m_mesh);
}

physx::PxGeometry *QConvexMeshShape::getPhysXGeometry()
{
    if (m_dirtyPhysx || m_scaleDirty) {
        updatePhysXGeometry();
    }
    return m_meshGeometry;
}

void QConvexMeshShape::updatePhysXGeometry()
{
    delete m_meshGeometry;
    m_meshGeometry = nullptr;

    auto *convexMesh = m_mesh->convexMesh();
    if (!convexMesh)
        return;

    auto meshScale = sceneScale();
    physx::PxMeshScale scale(physx::PxVec3(meshScale.x(), meshScale.y(), meshScale.z()),
                             physx::PxQuat(physx::PxIdentity));

    m_meshGeometry = new physx::PxConvexMeshGeometry(convexMesh, scale);
    m_dirtyPhysx = false;
}

const QUrl &QConvexMeshShape::meshSource() const
{
    return m_meshSource;
}

void QConvexMeshShape::setMeshSource(const QUrl &newMeshSource)
{
    if (m_meshSource == newMeshSource)
        return;
    m_meshSource = newMeshSource;
    m_mesh = QQuick3DPhysicsMeshManager::getMesh(m_meshSource, this);
    updatePhysXGeometry();

    m_dirtyPhysx = true;

    emit needsRebuild(this);
    emit meshSourceChanged();
}

QT_END_NAMESPACE