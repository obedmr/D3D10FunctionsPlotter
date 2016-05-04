//--------------------------------------------------------------------------------------
// Constant Buffers
//--------------------------------------------------------------------------------------


cbuffer cbPerFrame : register( b0 )
{
	matrix g_mWorld;                 // World matrix for object
	matrix g_mView;					 // View matrix for object
	matrix g_mProj;					 // View matrix for object
};


//------------------------------------------------------------
struct VS_INPUT2
{
	float3 vPosition	:POSITION;
	//float4 vColor		:COLOR0;
	//float3 vNormal		:NORMAL;
};

struct VS_OUTPUT
{
	float3 vPosition	:WORLDPOS;
	//float4 vColor		:COLOR0;
	//float3 vNormal		:NORMAL;
};
struct HS_OUTPUT
{
    float3 vPosition	: BEZIERPOS;
};
struct DS_OUTPUT
{
	float4 vPosition	: SV_POSITION;
	float3 v3DPos		: WORLDPOS;
};
struct GS_OUTPUT
{
	float4 vPosition	: SV_POSITION;
	float4 vColor		:COLOR0;
	float3 v3DPos		:WORLDPOS;
	float3 vNormal		:NORMAL;
};
struct PS_INPUT
{
	float4 vPosition	: SV_POSITION;
	float4 vColor		:COLOR0;
};

#define NUM_LIGHTS 3



float4 PhongModel(float4 Pos, float3 Normal)
{
	float3  g_vLightPos[NUM_LIGHTS] = {
		float3(0, 10, 0),
		float3(10, 0, 0),
		float3(-10, -10, 0)
	};
	float4  g_vLightColor[NUM_LIGHTS] = {
		float4(0.6, 0.6, 0.6, 1),
		float4(0, 0.2, 0.7, 1),
		float4(1, 0.3, 0, 1)
	};

	float4 g_Ambient = float4(0.3, 0.6, 0.3, 1);    // Material's ambient color
	float4 g_Diffuse = float4(0.7, 0.7, 0.7, 1);    // Material's diffuse color
	float4 g_Specular = float4(0.65, 0.65, 0.25, 1);

	float3 g_vEyePos = float3(2, 0, 2);
	float  g_PhongExp = 128.0f;

	float4 Color = g_Ambient;
	float3 EyeToPos = normalize(Pos.xyz - g_vEyePos.xyz);
	float3 LightToPos = float3(0, 0, 0), Reflected = float3(0, 0, 0);
	float4 LightPos = float4(0, 0, 0, 0);
	float DiffuseIntensity = 0, Spec = 0;

	int i = 0;

	for (i = 0; i < 3; i++)
	{
		LightPos = float4(g_vLightPos[i], 1);
		LightToPos = normalize(Pos.xyz - LightPos.xyz);

		// Compute the diffuse component
		DiffuseIntensity = saturate(dot(-LightToPos, Normal));

		// Compute the specular component
		Reflected = normalize(LightToPos - 2 * dot(Normal, LightToPos) * Normal);
		Spec = saturate(dot(-Reflected, EyeToPos));
		Spec = pow(max(Spec, 0), g_PhongExp);

		Color = Color + g_vLightColor[i] * ((DiffuseIntensity * g_Diffuse) + (Spec * g_Specular));

	}

	return Color;
}

//--------------------------------------------------------------------------
//Vertex shader
//--------------------------------------------------------------------------
VS_OUTPUT SmoothVS(VS_INPUT2 In)
{	
	VS_OUTPUT result;
    result.vPosition=mul(float4(In.vPosition, 1.0f), g_mWorld);

    return result;  
}


//----------------------------------------------------------------------------------
//	Basic Hull Shader
//
//----------------------------------------------------------------------------------

struct HS_CONSTANT_DATA_OUTPUT
{
    float Edges[4]			: SV_TessFactor;
    float Inside[2]			: SV_InsideTessFactor;
};


HS_CONSTANT_DATA_OUTPUT MyConstantsHS( InputPatch<VS_OUTPUT, 16> ip,
                                                 uint PatchID : SV_PrimitiveID )
{	
    HS_CONSTANT_DATA_OUTPUT Output;
    
	float TessAmount = 64.0f;
    Output.Edges[0] = Output.Edges[1] = Output.Edges[2] = Output.Edges[3] = TessAmount;
    Output.Inside[0] = Output.Inside[1] = TessAmount;
   
    return Output;
}
//----------------------------------------------------------------------------------
[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(16)]
[patchconstantfunc("MyConstantsHS")]
HS_OUTPUT SmoothHS( InputPatch<VS_OUTPUT, 16> p, 
                                     uint i : SV_OutputControlPointID,
                                     uint PatchID : SV_PrimitiveID )
{
    
    
    HS_OUTPUT Output;
    Output.vPosition=p[i].vPosition;
    return Output;
}



//--------------------------------------------------------------------
//Domain shader
//--------------------------------------------------------------------

float4 BernsteinBasis(float t){
	float invT = 1.0f - t;
	return float4(invT * invT * invT,
		3.0f * t * invT * invT,
		3.0f * t * t * invT,
		t * t * t);
}

float3 CubicBezierSum(const OutputPatch<HS_OUTPUT, 16> bezpatch,
	float4 basisU, float4 basisV){
	float3 sum = float3(0.0f, 0.0f, 0.0f);
		
		sum = basisV.x * (basisU.x*bezpatch[0].vPosition +
		basisU.y*bezpatch[1].vPosition +
		basisU.z*bezpatch[2].vPosition +
		basisU.w*bezpatch[3].vPosition);
		
	sum += basisV.y * (basisU.x*bezpatch[4].vPosition +
		basisU.y*bezpatch[5].vPosition +
		basisU.z*bezpatch[6].vPosition +
		basisU.w*bezpatch[7].vPosition);
		
	sum += basisV.z * (basisU.x*bezpatch[8].vPosition +
		basisU.y*bezpatch[9].vPosition +
		basisU.z*bezpatch[10].vPosition +
		basisU.w*bezpatch[11].vPosition);
		
	sum += basisV.w * (basisU.x*bezpatch[12].vPosition +
		basisU.y*bezpatch[13].vPosition +
		basisU.z*bezpatch[14].vPosition +
		basisU.w*bezpatch[15].vPosition);
	return sum;

}

[domain("quad")]
DS_OUTPUT SmoothDS( HS_CONSTANT_DATA_OUTPUT input, 
                        float2 UV : SV_DomainLocation,
                        const OutputPatch<HS_OUTPUT, 16> bezpatch )
{
    DS_OUTPUT Output;

	float4 basisU = BernsteinBasis(UV.x);
	float4 basisV = BernsteinBasis(UV.y);
	float3 WorldPos = CubicBezierSum(bezpatch, basisU, basisV);
	
	Output.vPosition =mul(float4(WorldPos,1.0f), g_mView);	
	Output.v3DPos =WorldPos;
    return Output;    
}

//--------------------------------------------------------------------
//Geometry shader
//--------------------------------------------------------------------


//---------------------------------------------------------------------------



[maxvertexcount(21)]
void SmoothGS( triangle DS_OUTPUT input[3], inout TriangleStream<GS_OUTPUT> TriStream )
{	
    float3 faceEdgeA = input[1].v3DPos - input[0].v3DPos;
    float3 faceEdgeB = input[2].v3DPos - input[0].v3DPos;
	float4 center = (input[2].vPosition + input[0].vPosition + input[1].vPosition) / 3;
    float3 faceNormal =cross(faceEdgeA, faceEdgeB);
    faceNormal = normalize( -faceNormal );
   
	float  Area = 2 * length(faceNormal);
	faceNormal = normalize(faceNormal);
	
	GS_OUTPUT vP0 = (GS_OUTPUT)0;
        
    vP0.vColor=float4(0.5,0.9,0.8,1.0);
	vP0.vPosition = input[0].vPosition ;
	vP0.vColor =float4(0,0,0,1);
	vP0.v3DPos =input[0].v3DPos;
	vP0.vNormal=faceNormal;
    TriStream.Append( vP0 );
    
    vP0.vPosition = input[1].vPosition;
	vP0.vColor =float4(0,0,0,1);
	vP0.v3DPos =input[1].v3DPos;
	vP0.vNormal=faceNormal;
    TriStream.Append( vP0 );
    
	vP0.vPosition = input[2].vPosition;
	vP0.vColor = float4(1, 0, 0, 1);
	vP0.v3DPos = input[2].v3DPos;
	vP0.vNormal = faceNormal;
	TriStream.Append(vP0);

	
	/*
	vP0.vColor = float4(0.5, 0.9, 0.8, 1.0);
	vP0.vPosition = center + float4(faceNormal*0.5, 0);
	//vP0.vColor = float4(0, 0, 0, 1);
	vP0.v3DPos = input[0].v3DPos;
	vP0.vNormal = faceNormal;
	TriStream.Append(vP0);

	vP0.vPosition = input[1].vPosition;
	//vP0.vColor = float4(0, 0, 0, 1);
	vP0.v3DPos = input[1].v3DPos;
	vP0.vNormal = faceNormal;
	TriStream.Append(vP0);

	vP0.vPosition = input[2].vPosition;
	//vP0.vColor = float4(1, 0, 0, 1);
	vP0.v3DPos = input[2].v3DPos;
	vP0.vNormal = faceNormal;
	TriStream.Append(vP0);
	*/
	TriStream.RestartStrip();
	
	
	
}

//--------------------------------------------------------------------
//Geometry shader
//--------------------------------------------------------------------
//---------------------------------------------------------------------------

[maxvertexcount(21)]
void FurGS( triangle DS_OUTPUT input[3], inout TriangleStream<GS_OUTPUT> TriStream )
{	
    
    float3 faceEdgeA = input[1].v3DPos - input[0].v3DPos;
    float3 faceEdgeB = input[2].v3DPos - input[0].v3DPos;
    float3 faceNormal =cross(faceEdgeA, faceEdgeB);
    faceNormal = normalize( -faceNormal );

	float2 RenderTargetSize = float2(2.0, 2.0);
	
	GS_OUTPUT vP0 = (GS_OUTPUT)0;
    
	
    vP0.vColor=float4(0.5,0.9,0.8,1.0);
    vP0.vPosition = input[0].vPosition;
	vP0.vColor =float4(0,0,0,1);
	vP0.v3DPos =input[0].v3DPos;
	vP0.vNormal=faceNormal;
    TriStream.Append( vP0 );
    
    vP0.vPosition = input[1].vPosition;
	vP0.vColor =float4(0,0,0,1);
	vP0.v3DPos =input[1].v3DPos;
	vP0.vNormal=faceNormal;
    TriStream.Append( vP0 );
    
    vP0.vPosition = input[2].vPosition;
    vP0.vColor =float4(0,0,0,1);
    vP0.v3DPos =input[2].v3DPos;
    vP0.vNormal=faceNormal;
    TriStream.Append( vP0 );
	TriStream.RestartStrip(); 

	float4 p0 = input[0].vPosition;
	float4 p1 = input[1].vPosition;

	float w0 = p0.w;
	float w1 = p1.w;

	p0.xyz /= p0.w;
	p1.xyz /= p1.w;

	float3 line01 = p1 - p0;
	float3 dir = normalize(line01);

	// scale to correct window aspect ratio
	float3 ratio = float3(RenderTargetSize.y, RenderTargetSize.x, 0);
	ratio = normalize(ratio);

	float3 unit_z = normalize(float3(0, 0, -1));

	float3 normal = normalize(cross(unit_z, dir) * ratio);

	float width = 0.0001;

	GS_OUTPUT v[4];

	float3 dir_offset = dir * ratio * width;
	float3 normal_scaled = normal * ratio * width;

	float3 p0_ex = p0 - dir_offset;
	float3 p1_ex = p1 + dir_offset;

	v[0].vPosition = float4(p0_ex - normal_scaled, 1) * w0;
	v[0].vColor = float4(0, 0, 1, 1);
	v[0].v3DPos = input[0].v3DPos;
	v[0].vNormal = normal;
	v[1].vPosition = float4(p0_ex + normal_scaled, 1) * w0;
	v[1].vColor = float4(0, 0, 1, 1);
	v[1].v3DPos = input[0].v3DPos;
	v[1].vNormal = normal;
	v[2].vPosition = float4(p1_ex + normal_scaled, 1) * w1;
	v[2].vColor = float4(0, 0, 1, 1);
	v[2].v3DPos = input[1].v3DPos;
	v[2].vNormal = normal;
	v[3].vPosition = float4(p1_ex - normal_scaled, 1) * w1;
	v[3].vColor = float4(0, 0, 1, 1);
	v[3].v3DPos = input[1].v3DPos;
	v[3].vNormal = normal;


	TriStream.Append(v[2]);
	TriStream.Append(v[1]);
	TriStream.Append(v[0]);

	TriStream.RestartStrip();

	TriStream.Append(v[3]);
	TriStream.Append(v[2]);
	TriStream.Append(v[0]);

	TriStream.RestartStrip();
	
}

//---------------------------------------------
float4 SmoothPS(GS_OUTPUT In) : SV_TARGET
{
	return  PhongModel(In.vPosition, In.vNormal);
}

