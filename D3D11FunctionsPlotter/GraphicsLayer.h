#pragma once
#ifndef CGraphics_LAYER
#define CGraphics_LAYER

class CGraphicsLayer
{

protected:
	//constructor
	CGraphicsLayer(HWND	hwnd);	

	//window handler
	HWND						 m_hWnd;

	//direc3d device and his context
	ID3D11Device				*m_pDevice;					
	ID3D11DeviceContext			*m_pDeviceContext;

	//BOOL						 m_bDeviceActive;

	//shaders
	ID3D11VertexShader			*m_pVSGouraud;
	ID3D11PixelShader			*m_pPSGouraud;
	ID3D11HullShader			*m_pHSSmooth;
	ID3D11DomainShader			*m_pDSSmooth;
	ID3D11GeometryShader		*m_pGSSmooth;
	ID3D11GeometryShader		*m_pGSFur;

	//options
	UINT						 m_wire;						
	bool						 m_pause;
	
	// DXGI Factory  and adapter object for the D3D11 device
	IDXGISwapChain				*m_pSwapChain;
	IDXGIFactory				*m_DXGIFactory;             
    IDXGIAdapter				*m_D3D11Adapter;            


	RECT						 m_rcScreenRect;
	ID3D11RenderTargetView		*m_pRenderTargetView;
	static CGraphicsLayer		*m_pGlobalGLayer;
	ID3D11Texture2D				*m_pBackBuffer;

	//Rasterizer
	ID3D11RasterizerState       *m_pRasterizerStateCullBack;
	ID3D11RasterizerState       *m_pRasterizerStateCullFront;
	ID3D11RasterizerState       *m_pRasterizerStateCullNone;
	

	ID3D11InputLayout			*m_pVertexLayout;
	ID3D11Texture2D				*m_pDepthStencilBuffer;
	ID3D11DepthStencilState		*m_pDepthStencilState;
	ID3D11DepthStencilView		*m_pDepthStencilView;

	D3DXMATRIXA16				 m_mWorld;
	D3DXMATRIXA16				 m_mProj;
	D3DXMATRIXA16				 m_mView;
	ID3D11Buffer				*m_pConstantsBuffer;
	ID3D11Buffer				*m_pConstantsBuffer2;
	

public:
	
	void DestroyAll();
	~CGraphicsLayer(void);
	void InitD3D(int Width,int Height,int bpp);
	ID3D11Device *GetDevice()
	{
		return m_pDevice;
	}
	ID3D11DeviceContext *GetDeviceContext()
	{
		return m_pDeviceContext;
	}
	ID3D11Texture2D	*GetBackBuffer()
	{
		return	m_pBackBuffer;
	}
	int Width() const
	{
		return m_rcScreenRect.right;
	}
	int Height() const
	{
		return m_rcScreenRect.bottom;
	}

	void Present();
	void ClearBackBuffer();

	static CGraphicsLayer *GetGraphics()
	{
		return m_pGlobalGLayer;
	}	
	static void Create(HWND hWnd,short width,short height);
	
	void SetWorldMtx(const D3DXMATRIX& mtxWorld){m_mWorld = mtxWorld;}
	void SetViewMtx(const D3DXMATRIX& mtxView){m_mView = mtxView;}
	void SetProjMtx(const D3DXMATRIX& mtxProj){m_mProj = mtxProj;}


	void CreateDepthStencilBuffer();
	int CreateDeviceAndSwapChain();
	void CreateViewport();
	int CreateShader();
	void ClearStencilBuffer();
	int CreateRasterizer();
	HRESULT CreateConstantsBuffer();
	
	
	ID3D11RasterizerState *GetRasterizerState();
	void UpdateMatrices();
	void UpdateTessellation();
	
	HRESULT CompileShaderFromFile( WCHAR* szFileName, LPCSTR szEntryPoint, LPCSTR szShaderModel, ID3D10Blob** ppBlobOut );
	void SetCullBack();
	void SetCullFront();
	void SetCullNone();
	void SetMatrices();
	void SetSmooth();
	void SetFur();
	


};
CGraphicsLayer *Graphics();


struct CONSTANTS_MATRICES
{
	D3DXMATRIX  g_mWorld;     // World matrix for object
	D3DXMATRIX  g_mView;		 // View matrix for object
	D3DXMATRIX  g_mProj;		 // View matrix for object
};

struct EXTRA_BUFFER
{
	float tessAmount;
};
#endif