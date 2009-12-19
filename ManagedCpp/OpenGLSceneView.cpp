﻿// ManagedCpp.cpp : main project file.

#include "OpenGLSceneView.h"

namespace ManagedCpp {

	const float perspectiveAngle = 45.0f;
	const float minDistance = 0.2f;
	const float maxDistance = 1000.0f;

	OpenGLSceneView::OpenGLSceneView()
	{
		InitializeComponent();

		camera = new Camera();
		camera->SetRadX(-45.0f * DEG_TO_RAD);
		camera->SetRadY(45.0f * DEG_TO_RAD);
		camera->SetZoom(20.0f);

		testMesh = gcnew Mesh();
		testMesh->MakeCube();
	}
	
	OpenGLSceneView::~OpenGLSceneView()
	{
		if (components)
		{
			delete components;
		}
	}

	void OpenGLSceneView::DrawGrid(int size, int step)
	{
		glBegin(GL_LINES);
		for (int x = -size; x <= size; x += step)
		{
			glVertex3i(x, 0, -size);
			glVertex3i(x, 0, size);
		}
		for (int z = -size; z <= size; z += step)
		{
			glVertex3i(-size, 0, z);
			glVertex3i(size, 0, z);
		}
		glEnd();
	}

	void OpenGLSceneView::RenderGL()
	{
		// Clear the background
		glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glLoadIdentity();

		ResizeGL();

		// Set the viewpoint
		glMatrixMode(GL_MODELVIEW);
		glLoadMatrixf(camera->GetViewMatrix());

		glDisable(GL_LIGHTING);

		glColor3f(0.1f, 0.1f, 0.1f);
		DrawGrid(10, 2);

		glEnable(GL_LIGHTING);

		testMesh->Draw(Vector3D(1, 1, 1), YES);

        glFlush();
	}

	void OpenGLSceneView::ResizeGL()
	{
		float w_h = (float)Width / (float)Height;

		glViewport(0, 0, Width, Height);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();			

		gluPerspective(perspectiveAngle, w_h, minDistance, maxDistance);
		glMatrixMode(GL_MODELVIEW);	
		glLoadIdentity();
	}

	#pragma region Mouse events

	void OpenGLSceneView::OnMouseDown(MouseEventArgs ^e)
	{
		UserControl::OnMouseDown(e);
		if (e->Button == System::Windows::Forms::MouseButtons::Middle)
		{
			lastPoint = PointF(e->X, e->Y);
		}
	}

	void OpenGLSceneView::OnMouseMove(MouseEventArgs ^e)
	{
		UserControl::OnMouseMove(e);
		if (e->Button == System::Windows::Forms::MouseButtons::Middle)
		{
			PointF point = PointF(e->X, e->Y);
			float diffX = point.X - lastPoint.X;
			float diffY = point.Y - lastPoint.Y;
			
			if ((this->ModifierKeys & System::Windows::Forms::Keys::Alt) == System::Windows::Forms::Keys::Alt)
			{
				const float sensitivity = 0.005f;
				camera->RotateLeftRight(diffX * sensitivity);
				camera->RotateUpDown(diffY * sensitivity);
			}
			else
			{
				RectangleF bounds = this->ClientRectangle;
				float w = bounds.Width;
				float h = bounds.Height;
				float sensitivity = (w + h) / 2.0f;
				sensitivity = 1.0f / sensitivity;
				camera->LeftRight(-diffX * camera->GetZoom() * sensitivity);
				camera->UpDown(-diffY * camera->GetZoom() * sensitivity);
			}
			
			lastPoint = point;
			this->Invalidate();
		}
	}

	void OpenGLSceneView::OnMouseUp(MouseEventArgs ^e)
	{
		UserControl::OnMouseUp(e);
	}

	void OpenGLSceneView::OnMouseWheel(MouseEventArgs ^e)
	{
		UserControl::OnMouseWheel(e);
		float zoom = e->Delta / 20.0f;
		float sensitivity = camera->GetZoom() * 0.02f;
		
		camera->Zoom(zoom * sensitivity);

		this->Invalidate();
	}

	#pragma endregion

	#pragma region OpenGL setup

	void OpenGLSceneView::OnLoad(EventArgs ^e)
	{
		UserControl::OnLoad(e);
		InitializeGL();
	}

	void OpenGLSceneView::OnSizeChanged(EventArgs ^e)
	{
		UserControl::OnSizeChanged(e);
		Invalidate();
	}

	void OpenGLSceneView::OnPaintBackground(PaintEventArgs ^e)
	{
		if (this->DesignMode)
			UserControl::OnPaintBackground(e);
	}

	void OpenGLSceneView::OnPaint(PaintEventArgs ^e)
	{
		if (this->DesignMode)
			return;

		if (!deviceContext || !glRenderingContext)
			return;

		BeginGL();
		RenderGL();
		SwapBuffers(deviceContext);
        EndGL();
	}

	void OpenGLSceneView::BeginGL()
	{
		 wglMakeCurrent(deviceContext, glRenderingContext);
	}
	
	void OpenGLSceneView::EndGL()
	{
		wglMakeCurrent(NULL, NULL);
	}

	void OpenGLSceneView::InitializeGL()
	{
        if (this->DesignMode)
			return;
        
		deviceContext = GetDC((HWND)this->Handle.ToPointer());
        // CAUTION: Not doing the following SwapBuffers() on the DC will
        // result in a failure to subsequently create the RC.
		SwapBuffers(deviceContext);

        //Get the pixel format		
        PIXELFORMATDESCRIPTOR pfd;
		ZeroMemory(&pfd, sizeof(pfd));
		pfd.nSize = sizeof(pfd);
        pfd.nVersion = 1;
        pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cColorBits = 32;
        pfd.cDepthBits = 32;
        pfd.iLayerType = PFD_MAIN_PLANE;

        int pixelFormatIndex = ChoosePixelFormat(deviceContext, &pfd);
        if (pixelFormatIndex == 0)
        {
			Trace::WriteLine("Unable to retrieve pixel format");
            return;
        }

        if (SetPixelFormat(deviceContext, pixelFormatIndex, &pfd) == 0)
        {
			Trace::WriteLine("Unable to set pixel format");
            return;
        }
        //Create rendering context
        glRenderingContext = wglCreateContext(deviceContext);
        if (!glRenderingContext)
        {
			Trace::WriteLine("Unable to get rendering context");
            return;
        }
		if (wglMakeCurrent(deviceContext, glRenderingContext) == 0)
        {
			Trace::WriteLine("Unable to make rendering context current");
            return;
        }
        //Set up OpenGL related characteristics
        ResizeGL();
        BeginGL();
        glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);

		// Configure the view
		glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
		glShadeModel(GL_SMOOTH);
		glEnable(GL_LIGHTING);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_LIGHT0);

        EndGL();
	}	

	#pragma endregion
}