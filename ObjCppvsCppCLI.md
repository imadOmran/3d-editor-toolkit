# Objective-C++ vs C++/CLI #

I started this project as Mac only. I needed to learn a lot about Cocoa and Objective-C so I don't cared about cross platform code and enjoyed Mac specific things.
Then I got two requests about Windows version of this editor. So I started thinking about it. There was two main possibilities. First, rewrite most of code into C++ and use some cross platform GUI toolkit like Qt. With Qt-like toolkits is problem that they behaves differently than traditional Cocoa apps. They also behaves slightly differently than Windows apps written in MFC or .NET framework. Another problem is that many developers knows best their own platform. Many cross platform tools forces you to learn yet another windowing toolkit so your investments in platform specific libraries are gone. The last nail into coffin of only cross platform C++ was that my original interest was to learn a lot about Cocoa and Objective-C in larger app.
Second approach, I think not many people gone this way. I rewrote lot parts into C++/CLI for .NET framework. So nearly every class except from some general math and drawing have two complete re-implementations, Objective-C++ and C++/CLI. You may wonder why I don't rewrote it into C#, reason is very simple, C# can't do things that Objective-C++ or C++/CLI can, for example C# class cannot contain pure C++ member.
It was really nice learning experience and it still is. What was really interesting is that it wasn't so much time consuming as I expected. It looks that many parts of .NET framework is modeled after Cocoa. Things that were missing in stock Microsoft libraries were added into HotChocolate library which is written in C#.
More GUI specific parts (code in Form1) and whole design of app is written in C#, because it is much easier to do than in C++/CLI.
Good thing about this is that I don't know any open-source C++ library with so many things for GUI that are in Cocoa or .NET framework. With this approach you can extend the project further for example only Windows way with lot of libraries at http://www.codeproject.com or use it for some Mac only app.

# Examples #

Rest of this wiki page is used for actual examples of how this translation exactly works.

So first begin with some simple artificial example:

## Class declaration in Objective-C++ ##

```
@interface ClassName
{
    // fields
    int x, y, width, height;
}

// properties
@property (readwrite, assign) int x;
@property (readwrite, assign) int y;
@property (readwrite, assign) int width;
@property (readwrite, assign) int height; 

// methods
- (id)initWithX:(int)anX y:(int)anY width:(int)aWidth height:(int)aHeight;
- (void)someMethodWithX:(int)anX y:(int)anY width:(int)aWidth height:(int)aHeight;

@end
```

## Class declaration in C++/CLI ##

```
public ref class ClassName
{
private: // fields
  int x, y, width, height;
public: // properties and methods
  property int X { int get(); void set(int value); }
  property int Y { int get(); void set(int value); }
  property int Width { int get(); void set(int value); }
  property int Height { int get(); void set(int value); }
  
  ClassName(int x, int y, int width, int height);
  ~ClassName();
  
  void SomeMethod(int x, int y, int width, int height);
};
```

## Class implementation in Objective-C++ ##

```
@implementation ClassName

@synthesize x, y, width, height;

- (id)initWithX:(int)anX y:(int)anY width:(int)aWidth height:(int)aHeight
{
    self = [super init];
    if (self)
    {
        // methods are called with [obj method] syntax, 
        // instead of obj.method() or obj->method() syntax
        // self == this
        [self someMethodWithX:anX y:anY width:aWidth height:aHeight];
    }
    return self;
}

- (void)dealloc
{
    // nothing to release here
    [super dealloc];
}

- (void)someMethodWithX:(int)anX y:(int)anY width:(int)aWidth height:(int)aHeight
{
    x = anX;
    y = anY;
    width = aWidth;
    height = aHeight;
}

@end
```

## Class implementation in C++/CLI ##

```
ClassName::ClassName(int x, int y, int width, int height)
{
    // syntax is classical for C++, obj->method() works as expected
    this->SomeMethod(x, y, width, height);
}

ClassName::~ClassName()
{
    // nothing to delete here
}

int ClassName::X::get()
{
    return x;
}

void ClassName::X::set(int value)
{
    x = value;
}

int ClassName::Y::get()
{
    return y;
}

void ClassName::Y::set(int value)
{
    y = value;
}

int ClassName::Width::get()
{
    return width;
}

void ClassName::Width::set(int value)
{
    width = value;
}

int ClassName::Height::get()
{
    return height;
}

void ClassName::Height::set(int value)
{
    height = value;
}

void ClassName::SomeMethod(int x, int y, int width, int height)
{
    this->x = x;
    this->y = y;
    this->width = width;
    this->height = height;
}

```

## Advanced stuff ##

So we covered the basics. C++/CLI is not the most feature complete language for .NET, it is interesting that some features is only in C#, VB.NET or C++/CLI, no language has all features like Objective-C++ for Mac.
I really like to learn new features of programming languages, so I started more with lambda syntax introduced in C# 3.0. This feature enables you to pass method body as argument to another method.

### C# 3.0 lambda syntax (Visual Studio 2008) ###

```
void OnEachViewDo(Action<OpenGLSceneView> actionOnView)
{
    actionOnView(openGLSceneViewLeft);
    actionOnView(openGLSceneViewTop);
    actionOnView(openGLSceneViewFront);
    actionOnView(openGLSceneViewPerspective);
}

void Usage()
{
    // redraws all views
    OnEachViewDo(view => view.Invalidate());
}
```

`OnEachViewDo` is called on each view. After `=>` is body of method. You can learn more about it at http://msdn.microsoft.com/en-us/library/bb397687.aspx

### Objective-C 2.1 version (Snow Leopard) ###

```
// declaration in .h file
- (void)onEachViewDoAction:(void (^viewAction)(OpenGLSceneView *view))actionOnView;

// implementation in .mm file

- (void)onEachViewDoAction:(void (^viewAction)(OpenGLSceneView *view))actionOnView
{
	actionOnView(viewTop);
	actionOnView(viewLeft);
	actionOnView(viewFront);
	actionOnView(viewPerspective);
}

- (void)usage
{
    // redraw all views
    [self onEachViewDoAction:^ (OpenGLSceneView *view) { [view setNeedsDisplay:YES]; }];
}
```

Syntax for lambdas in Objective-C 2.1 isn't as good as in C#, but with more complicated examples, both are ugly. I currently removed many of those syntax, because otherwise it doesn't compile for Leopard. I use it now only in unit tests. More about this syntax is at http://cocoawithlove.com/2009/10/ugly-side-of-blocks-explicit.html