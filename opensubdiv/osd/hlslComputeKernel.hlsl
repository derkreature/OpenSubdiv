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

interface IComputeKernel {
    void runKernel( uint3 ID );
};
IComputeKernel kernel;

cbuffer KernelCB : register( b0 ) {
    int vertexOffset;   // vertex index offset for the batch
    int tableOffset;    // offset of subdivision table
    int indexStart;     // start index relative to tableOffset
    int indexEnd;       // end index relative to tableOffset
    int vertexBaseOffset;  // base vbo offset of the vertex buffer
    int varyingBaseOffset; // base vbo offset of the varying buffer
    bool vertexPass;

// vertex edit kernel
    int editPrimVarOffset;
    int editPrimVarWidth;
};

/*
 +-----+---------------------------------+-----
   n-1 |   Level n   |<batch range>|     |  n+1
 +-----+---------------------------------+-----
       ^             ^             ^
  vertexOffset       |             |
                 indexStart     indexEnd
*/

RWBuffer<float> vertexBuffer  : register( u0 );
RWBuffer<float> varyingBuffer : register( u1 );
Buffer<int> _F_IT             : register( t2 );
Buffer<int> _F_ITa            : register( t3 );
Buffer<int> _E_IT             : register( t4 );
Buffer<int> _V_IT             : register( t5 );
Buffer<int> _V_ITa            : register( t6 );
Buffer<float> _E_W            : register( t7 );
Buffer<float> _V_W            : register( t8 );
Buffer<int> _editIndices      : register( t9 );
Buffer<float> _editValues     : register( t10 );

//--------------------------------------------------------------------------------

struct Vertex
{
#if NUM_VERTEX_ELEMENTS > 0
    float vertexData[NUM_VERTEX_ELEMENTS];
#endif
#if NUM_VARYING_ELEMENTS > 0
    float varyingData[NUM_VARYING_ELEMENTS];
#endif
};

void clear(out Vertex v)
{
#if NUM_VERTEX_ELEMENTS > 0
    for(int i = 0; i < NUM_VERTEX_ELEMENTS; i++) {
        v.vertexData[i] = 0;
    }
#endif
#if NUM_VARYING_ELEMENTS > 0
    for(int i = 0; i < NUM_VARYING_ELEMENTS; i++){
        v.varyingData[i] = 0;
    }
#endif
}

Vertex readVertex(int index)
{
    Vertex v;

#if NUM_VERTEX_ELEMENTS > 0
    int vertexIndex = index * VERTEX_STRIDE + vertexBaseOffset;
    for (int i = 0; i < NUM_VERTEX_ELEMENTS; i++) {
        v.vertexData[i] = vertexBuffer[vertexIndex + i];
    }
#endif
#if NUM_VARYING_ELEMENTS > 0
    int varyingIndex = index * VARYING_STRIDE + varyingBaseOffset;
    for (int i = 0; i < NUM_VARYING_ELEMENTS; i++) {
        v.varyingData[i] = varyingBuffer[varyingIndex + i];
    }
#endif
    return v;
}

void writeVertex(int index, Vertex v)
{
#if NUM_VERTEX_ELEMENTS > 0
    int vertexIndex = index * VERTEX_STRIDE + vertexBaseOffset;
    for (int i = 0; i < NUM_VERTEX_ELEMENTS; i++) {
        vertexBuffer[vertexIndex + i] = v.vertexData[i];
    }
#endif
#if NUM_VARYING_ELEMENTS > 0
    int varyingIndex = index * VARYING_STRIDE + varyingBaseOffset;
    for (int i = 0; i < NUM_VARYING_ELEMENTS; i++) {
        varyingBuffer[varyingIndex + i] = v.varyingData[i];
    }
#endif
}

void addWithWeight(inout Vertex v, Vertex src, float weight)
{
#if NUM_VERTEX_ELEMENTS > 0
    for (int i = 0; i < NUM_VERTEX_ELEMENTS; i++) {
        v.vertexData[i] += weight * src.vertexData[i];
    }
#endif
}

void addVaryingWithWeight(inout Vertex v, Vertex src, float weight)
{
#if NUM_VARYING_ELEMENTS > 0
    for (int i = 0; i < NUM_VARYING_ELEMENTS; i++) {
        v.varyingData[i] += weight * src.varyingData[i];
    }
#endif
}

//--------------------------------------------------------------------------------
// Face-vertices compute Kernel
class CatmarkComputeFace : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int h = _F_ITa[2*i];
    int n = _F_ITa[2*i+1];

    float weight = 1.0/n;

    Vertex dst;
    clear(dst);
    for(int j=0; j<n; ++j){
        int index = _F_IT[h+j];
        addWithWeight(dst, readVertex(index), weight);
        addVaryingWithWeight(dst, readVertex(index), weight);
    }
    writeVertex(vid, dst);
}
};

// Quad face-vertices compute Kernel
class CatmarkComputeQuadFace : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;

    int fidx0 = _F_IT[tableOffset + 4 * i + 0];
    int fidx1 = _F_IT[tableOffset + 4 * i + 1];
    int fidx2 = _F_IT[tableOffset + 4 * i + 2];
    int fidx3 = _F_IT[tableOffset + 4 * i + 3];

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(fidx0), 0.25f);
    addWithWeight(dst, readVertex(fidx1), 0.25f);
    addWithWeight(dst, readVertex(fidx2), 0.25f);
    addWithWeight(dst, readVertex(fidx3), 0.25f);
    addVaryingWithWeight(dst, readVertex(fidx0), 0.25f);
    addVaryingWithWeight(dst, readVertex(fidx1), 0.25f);
    addVaryingWithWeight(dst, readVertex(fidx2), 0.25f);
    addVaryingWithWeight(dst, readVertex(fidx3), 0.25f);

    writeVertex(vid, dst);
}
};

// Tri-quad face-vertices compute Kernel
class CatmarkComputeTriQuadFace : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;

    int fidx0 = _F_IT[tableOffset + 4 * i + 0];
    int fidx1 = _F_IT[tableOffset + 4 * i + 1];
    int fidx2 = _F_IT[tableOffset + 4 * i + 2];
    int fidx3 = _F_IT[tableOffset + 4 * i + 3];
    bool isTriangle = (fidx2 == fidx3);
    float weight = (isTriangle ? 1.0f / 3.0f : 1.0f / 4.0f);

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(fidx0), weight);
    addWithWeight(dst, readVertex(fidx1), weight);
    addWithWeight(dst, readVertex(fidx2), weight);
    addVaryingWithWeight(dst, readVertex(fidx0), weight);
    addVaryingWithWeight(dst, readVertex(fidx1), weight);
    addVaryingWithWeight(dst, readVertex(fidx2), weight);
    if (!isTriangle) {
        addWithWeight(dst, readVertex(fidx3), weight);
        addVaryingWithWeight(dst, readVertex(fidx3), weight);
    }

    writeVertex(vid, dst);
}
};

// Edge-vertices compute Kernel
class CatmarkComputeEdge : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    Vertex dst;
    clear(dst);

    int eidx0 = _E_IT[4*i+0];
    int eidx1 = _E_IT[4*i+1];
    int eidx2 = _E_IT[4*i+2];
    int eidx3 = _E_IT[4*i+3];
    int4 eidx = int4(eidx0, eidx1, eidx2, eidx3);

    float vertWeight = _E_W[i*2+0];

    // Fully sharp edge : vertWeight = 0.5f;
    addWithWeight(dst, readVertex(eidx.x), vertWeight);
    addWithWeight(dst, readVertex(eidx.y), vertWeight);

    if(eidx.z != -1){
        float faceWeight = _E_W[i*2+1];

        addWithWeight(dst, readVertex(eidx.z), faceWeight);
        addWithWeight(dst, readVertex(eidx.w), faceWeight);
    }

    addVaryingWithWeight(dst, readVertex(eidx.x), 0.5f);
    addVaryingWithWeight(dst, readVertex(eidx.y), 0.5f);

    writeVertex(vid, dst);
}
};

// Restricted edge-vertices compute Kernel
class CatmarkComputeRestrictedEdge : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    Vertex dst;
    clear(dst);

    int eidx0 = _E_IT[4*i+0];
    int eidx1 = _E_IT[4*i+1];
    int eidx2 = _E_IT[4*i+2];
    int eidx3 = _E_IT[4*i+3];
    int4 eidx = int4(eidx0, eidx1, eidx2, eidx3);

    addWithWeight(dst, readVertex(eidx.x), 0.25f);
    addWithWeight(dst, readVertex(eidx.y), 0.25f);
    addWithWeight(dst, readVertex(eidx.z), 0.25f);
    addWithWeight(dst, readVertex(eidx.w), 0.25f);
    addVaryingWithWeight(dst, readVertex(eidx.x), 0.5f);
    addVaryingWithWeight(dst, readVertex(eidx.y), 0.5f);

    writeVertex(vid, dst);
}
};

// Edge-vertices compute Kernel (bilinear scheme)
class BilinearComputeEdge : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    Vertex dst;
    clear(dst);

    int2 eidx = int2(_E_IT[2*i+0],
                     _E_IT[2*i+1]);

    addWithWeight(dst, readVertex(eidx.x), 0.5f);
    addWithWeight(dst, readVertex(eidx.y), 0.5f);

    addVaryingWithWeight(dst, readVertex(eidx.x), 0.5f);
    addVaryingWithWeight(dst, readVertex(eidx.y), 0.5f);

    writeVertex(vid, dst);
}
};

// Vertex-vertices compute Kernel (bilinear scheme)
class BilinearComputeVertex : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    Vertex dst;
    clear(dst);

    int p = _V_ITa[i];

    addWithWeight(dst, readVertex(p), 1.0f);

    addVaryingWithWeight(dst, readVertex(p), 1.0f);

    writeVertex(vid, dst);
}
};

// Vertex-vertices compute Kernels 'A' / k_Crease and k_Corner rules
class CatmarkComputeVertexA : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int n     = _V_ITa[5*i+1];
    int p     = _V_ITa[5*i+2];
    int eidx0 = _V_ITa[5*i+3];
    int eidx1 = _V_ITa[5*i+4];

    float weight = vertexPass
        ? _V_W[i]
        : 1.0 - _V_W[i];

    // In the case of fractional weight, the weight must be inverted since
    // the value is shared with the k_Smooth kernel (statistically the
    // k_Smooth kernel runs much more often than this one)
    if (weight>0.0 && weight<1.0 && n > 0)
        weight=1.0-weight;

    Vertex dst;
    if(! vertexPass)
        clear(dst);
    else
        dst = readVertex(vid);

    if (eidx0==-1 || (vertexPass==false && (n==-1)) ) {
        addWithWeight(dst, readVertex(p), weight);
    } else {
        addWithWeight(dst, readVertex(p), weight * 0.75f);
        addWithWeight(dst, readVertex(eidx0), weight * 0.125f);
        addWithWeight(dst, readVertex(eidx1), weight * 0.125f);
    }
    if(! vertexPass)
        addVaryingWithWeight(dst, readVertex(p), 1);

    writeVertex(vid, dst);
}
};

// Vertex-vertices compute Kernels 'B' / k_Dart and k_Smooth rules
class CatmarkComputeVertexB : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int h = _V_ITa[5*i];
    int n = _V_ITa[5*i+1];
    int p = _V_ITa[5*i+2];

    float weight = _V_W[i];
    float wp = 1.0/float(n*n);
    float wv = (n-2.0) * n * wp;

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(p), weight * wv);

    for(int j = 0; j < n; ++j){
        addWithWeight(dst, readVertex(_V_IT[h+j*2]), weight * wp);
        addWithWeight(dst, readVertex(_V_IT[h+j*2+1]), weight * wp);
    }
    addVaryingWithWeight(dst, readVertex(p), 1);
    writeVertex(vid, dst);
}
};

// Restricted vertex-vertices compute Kernels 'A' / k_Crease and k_Corner rules
class CatmarkComputeRestrictedVertexA : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int p     = _V_ITa[5*i+2];
    int eidx0 = _V_ITa[5*i+3];
    int eidx1 = _V_ITa[5*i+4];

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(p), 0.75f);
    addWithWeight(dst, readVertex(eidx0), 0.125f);
    addWithWeight(dst, readVertex(eidx1), 0.125f);
    addVaryingWithWeight(dst, readVertex(p), 1);

    writeVertex(vid, dst);
}
};

// Restricted vertex-vertices compute Kernels 'B' / regular k_Dart and k_Smooth rules
class CatmarkComputeRestrictedVertexB1 : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int h = _V_ITa[5*i];
    int p = _V_ITa[5*i+2];

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(p), 0.5f);
    for(int j = 0; j < 8; ++j)
        addWithWeight(dst, readVertex(_V_IT[h+j]), 0.0625f);
    addVaryingWithWeight(dst, readVertex(p), 1);
    writeVertex(vid, dst);
}
};

// Restricted vertex-vertices compute Kernels 'B' / irregular k_Dart and k_Smooth rules
class CatmarkComputeRestrictedVertexB2 : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int h = _V_ITa[5*i];
    int n = _V_ITa[5*i+1];
    int p = _V_ITa[5*i+2];

    float wp = 1.0/float(n*n);
    float wv = (n-2.0) * n * wp;

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(p), wv);
    for(int j = 0; j < n; ++j){
        addWithWeight(dst, readVertex(_V_IT[h+j*2]), wp);
        addWithWeight(dst, readVertex(_V_IT[h+j*2+1]), wp);
    }
    addVaryingWithWeight(dst, readVertex(p), 1);
    writeVertex(vid, dst);
}
};

// Vertex-vertices compute Kernels 'B' / k_Dart and k_Smooth rules
class LoopComputeVertexB : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    float PI = 3.14159265358979323846264;
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    int vid = i + vertexOffset;
    i += tableOffset;

    int h = _V_ITa[5*i];
    int n = _V_ITa[5*i+1];
    int p = _V_ITa[5*i+2];

    float weight = _V_W[i];
    float wp = 1.0/n;
    float beta = 0.25 * cos(PI*2.0f*wp)+0.375f;
    beta = beta * beta;
    beta = (0.625f-beta)*wp;

    Vertex dst;
    clear(dst);

    addWithWeight(dst, readVertex(p), weight * (1.0-(beta*n)));

    for(int j = 0; j < n; ++j){
        addWithWeight(dst, readVertex(_V_IT[h+j]), weight * beta);
    }
    addVaryingWithWeight(dst, readVertex(p), 1);
    writeVertex(vid, dst);
}
};

class EditAdd : IComputeKernel {
int placeholder;
void runKernel( uint3 ID )
{
    int i = int(ID.x) + indexStart;
    if (i >= indexEnd) return;
    i += tableOffset;

    int v = _editIndices[i];
    Vertex dst = readVertex(v + vertexOffset);

    // seemingly we can't iterate dynamically over vertexData[n]
    // due to mysterious glsl runtime limitation...?
    for (int j = 0; j < NUM_VERTEX_ELEMENTS; ++j) {
        float editValue = _editValues[i*editPrimVarOffset+min(j, editPrimVarWidth)];
        editValue *= float(j >= editPrimVarOffset);
        editValue *= float(j < (editPrimVarWidth + editPrimVarOffset));
        dst.vertexData[j] += editValue;
    }
    writeVertex(v + vertexOffset, dst);
}
};

CatmarkComputeFace catmarkComputeFace;
CatmarkComputeQuadFace catmarkComputeQuadFace;
CatmarkComputeTriQuadFace catmarkComputeTriQuadFace;
CatmarkComputeEdge catmarkComputeEdge;
CatmarkComputeRestrictedEdge catmarkComputeRestrictedEdge;
BilinearComputeEdge bilinearComputeEdge;
BilinearComputeVertex bilinearComputeVertex;
CatmarkComputeVertexA catmarkComputeVertexA;
CatmarkComputeVertexB catmarkComputeVertexB;
CatmarkComputeRestrictedVertexA catmarkComputeRestrictedVertexA;
CatmarkComputeRestrictedVertexB1 catmarkComputeRestrictedVertexB1;
CatmarkComputeRestrictedVertexB2 catmarkComputeRestrictedVertexB2;
LoopComputeVertexB loopComputeVertexB;
EditAdd editAdd;

[numthreads(WORK_GROUP_SIZE, 1, 1)]
void cs_main( uint3 ID : SV_DispatchThreadID )
{
    // call kernel
    kernel.runKernel(ID);
}
