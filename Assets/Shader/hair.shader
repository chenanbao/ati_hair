Shader "hair"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_SpecColor1 ("SpecColor1", Color) = (1,1,1,1)		
		_SpecColor2 ("SpecColor2", Color) = (1,1,1,1)
		_Normalmap("Normalmap", 2D) = "bump" {}
		_BumpSize("BumpSize",Range(0,3))=1
		_SpecularTex("Specular(R)Spec shift(G)SpecMask(B)", 2D) = "white" {}
		_shiftValue("shift", Float) = 0.5
		_shiftSpec2("shift2",Range(-0.5,0.5))=0.5
		_Gloss("Gloss", Range(0,100)) = 1
		_Specular("Specular", Range( 0 , 1)) = 0
	}
 
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off		

		Pass
		{   
		    Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#define UNITY_PASS_FORWARDBASE
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;				
			};
 
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
 
				float3 worldTangent : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;				
				float3 worldPos : TEXCOORD3;	
				float3 worldBitangent:TEXCOORD4;
			};

			uniform sampler2D _MainTex;
 
			uniform fixed4 _SpecColor1;
			uniform fixed4 _SpecColor2;
			uniform sampler2D _Normalmap;
			uniform sampler2D _SpecularTex;
			uniform float _shiftValue;
			uniform float _shiftSpec2;
			uniform float _Gloss;
			uniform float _Specular;
			uniform float4 _MainTex_ST;
			uniform float _BumpSize;

			float3 shiftTangent( float3 T , float3 N , float Shift )
			{
				half3 ShiftT =T+ N *Shift;
				return normalize(ShiftT);
			}
			

			half StrandSpecular( half3 T , half3 V , half3 L , half Exponent )
			{
				half3 H =normalize(L+V);
				float dotTH= dot(T,H);
				float sinTH=sqrt(1-dotTH*dotTH);
				float dirAtten =smoothstep(-1,0,dotTH);
				return dirAtten*pow(sinTH,Exponent);
			}
 
 
			v2f vert ( appdata v )
			{
				v2f o;
				
				o.worldTangent = UnityObjectToWorldDir(v.tangent);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;					
				o.worldBitangent = cross( o.worldNormal,o.worldTangent );
 

				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);				
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
 
			fixed4 frag (v2f i ) : SV_Target
			{			
				fixed4 albedo = tex2D( _MainTex, i.uv );
				float4 spectex = tex2D( _SpecularTex, i.uv);
 
				float3 TtoW0 = float3( i.worldTangent.x, i.worldBitangent.x, i.worldNormal.x);
				float3 TtoW1 = float3( i.worldTangent.y, i.worldBitangent.y, i.worldNormal.y);
				float3 TtoW2 = float3( i.worldTangent.z, i.worldBitangent.z, i.worldNormal.z);
				//获取法线贴图处理后的世界法线，增加法线的影响
				float3 normal = UnpackNormal( tex2D( _Normalmap, i.uv ) );		
				normal.xy*=_BumpSize;
				normal.z = sqrt(1.0- saturate(dot(normal.xy ,normal.xy)));
 
				float3 Wnormal = float3 (dot(TtoW0,normal),dot(TtoW1,normal),dot(TtoW2,normal));
				Wnormal= normalize(Wnormal);
 
				float3 tan= - normalize(cross( Wnormal , i.worldTangent ));	

				float shift1 = spectex.g - 0.5 + _shiftValue ;
				float shift2 = spectex.g - 0.5 + _shiftValue - _shiftSpec2 ;

				float3 T1 = shiftTangent( tan , Wnormal , shift1);
				float3 T2 = shiftTangent(tan , Wnormal , shift2);
				float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 L = normalize(_WorldSpaceLightPos0.xyz);

				float NdotL =saturate(dot(Wnormal,L));
				float3 diff =saturate(lerp(0.25,1,NdotL));

				float3 spec = StrandSpecular( T1 , V , L ,_Gloss )* _SpecColor1;
				spec = spec + StrandSpecular( T2 , V , L ,_Gloss )* _SpecColor2 * spectex.b  *_Specular;					
 
				fixed4 col;
				col.rgb =  albedo.rgb *( diff+spec)*NdotL ;
				col.a = albedo.a;
				return col;
			}
			ENDCG
		}
	}
}