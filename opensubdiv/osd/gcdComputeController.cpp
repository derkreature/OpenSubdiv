//
//   Copyright 2013 Pixar
//
//   Licensed under the Apache License, Version 2.0 (the "Apache License")
//   with the following modification; you may not use this file except in
//   compliance with the Apache License and the following modification to it:
//   Section 6. Trademarks. is deleted and replaced with:
//
//   6. Trademarks. This License does not grant permission to use the trade
//      names, trademarks, service marks, or product names of the Licensor
//      and its affiliates, except as required to comply with Section 4(c) of
//      the License and to reproduce the content of the NOTICE file.
//
//   You may obtain a copy of the Apache License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the Apache License with the above modification is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//   KIND, either express or implied. See the Apache License for the specific
//   language governing permissions and limitations under the Apache License.
//

#include "../osd/cpuComputeContext.h"
#include "../osd/gcdComputeController.h"
#include "../osd/gcdKernel.h"

namespace OpenSubdiv {
namespace OPENSUBDIV_VERSION {


OsdGcdComputeController::OsdGcdComputeController() {
    _gcd_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

void
OsdGcdComputeController::ApplyBilinearFaceVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeFace(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::F_IT)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::F_ITa)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
	_gcd_queue);
}

void
OsdGcdComputeController::ApplyBilinearEdgeVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeBilinearEdge(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::E_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
	_gcd_queue);
}

void
OsdGcdComputeController::ApplyBilinearVertexVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeBilinearVertex(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkFaceVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeFace(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::F_IT)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::F_ITa)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkQuadFaceVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeQuadFace(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::F_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkTriQuadFaceVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeTriQuadFace(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::F_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkEdgeVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeEdge(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::E_IT)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::E_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkRestrictedEdgeVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeRestrictedEdge(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::E_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkVertexVerticesKernelB(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeVertexB(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::V_IT)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkVertexVerticesKernelA1(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeVertexA(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(), false,
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkVertexVerticesKernelA2(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeVertexA(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(), true,
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkRestrictedVertexVerticesKernelB1(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeRestrictedVertexB1(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::V_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkRestrictedVertexVerticesKernelB2(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeRestrictedVertexB2(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::V_IT)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyCatmarkRestrictedVertexVerticesKernelA(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeRestrictedVertexA(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyLoopEdgeVerticesKernel(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeEdge(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::E_IT)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::E_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyLoopVertexVerticesKernelB(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeLoopVertexB(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const int*)context->GetTable(FarSubdivisionTables::V_IT)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(),
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyLoopVertexVerticesKernelA1(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeVertexA(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(), false,
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyLoopVertexVerticesKernelA2(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    OsdGcdComputeVertexA(
        _currentBindState.vertexBuffer, _currentBindState.varyingBuffer,
        _currentBindState.vertexDesc, _currentBindState.varyingDesc,
        (const int*)context->GetTable(FarSubdivisionTables::V_ITa)->GetBuffer(),
        (const float*)context->GetTable(FarSubdivisionTables::V_W)->GetBuffer(),
        batch.GetVertexOffset(), batch.GetTableOffset(), batch.GetStart(), batch.GetEnd(), true,
        _gcd_queue);
}

void
OsdGcdComputeController::ApplyVertexEdits(
    FarKernelBatch const &batch, OsdCpuComputeContext const *context) const {

    assert(context);

    const OsdCpuHEditTable *edit = context->GetEditTable(batch.GetTableIndex());
    assert(edit);

    const OsdCpuTable * primvarIndices = edit->GetPrimvarIndices();
    const OsdCpuTable * editValues = edit->GetEditValues();

    if (edit->GetOperation() == FarVertexEdit::Add) {
        OsdGcdEditVertexAdd(_currentBindState.vertexBuffer,
                            _currentBindState.vertexDesc,
                            edit->GetPrimvarOffset(),
                            edit->GetPrimvarWidth(),
                            batch.GetVertexOffset(),
                            batch.GetTableOffset(),
                            batch.GetStart(),
                            batch.GetEnd(),
                            static_cast<unsigned int*>(primvarIndices->GetBuffer()),
                            static_cast<float*>(editValues->GetBuffer()),
                            _gcd_queue);
    } else if (edit->GetOperation() == FarVertexEdit::Set) {
        OsdGcdEditVertexSet(_currentBindState.vertexBuffer,
                            _currentBindState.vertexDesc,
                            edit->GetPrimvarOffset(),
                            edit->GetPrimvarWidth(),
                            batch.GetVertexOffset(),
                            batch.GetTableOffset(),
                            batch.GetStart(),
                            batch.GetEnd(),
                            static_cast<unsigned int*>(primvarIndices->GetBuffer()),
                            static_cast<float*>(editValues->GetBuffer()),
                            _gcd_queue);
    }
}

void
OsdGcdComputeController::Synchronize() {
}

}  // end namespace OPENSUBDIV_VERSION
}  // end namespace OpenSubdiv

