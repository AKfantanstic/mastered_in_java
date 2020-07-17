### 1. 代码解释什么是循环引用:

```
class  A {
    public B bb;
}

class  B {
    public A aa;
}

public class TestGC {

    public static  void main(String[] args) {
	A a = new A();
	B b = new B();

	a.bb = b;
	b.aa = a;

	a = null;
	b = null;
    }
}
```
在上面的代码示例中，假设我们有两个类分别是A和B，A类中有一个字段是B类的类型，B类中有一个字段是A类类型，现在分别new一个A类对象和new一个B类对象，此时引用a指向刚new出来的A类对象，引用b指向刚new出来的B类对象,然后将两个类中的字段互相引用一下，这样即使下面进行a = null和b = null，但是A类对象仍然被B类对象中的字段引用着，尽管现在A类和B类独享都已经访问不到了，但是引用计数却都不为0.

### 2. 双亲委派模型：
当一个类收到了类加载请求，他首先不会尝试自己去加载这个类，而是把这个请求委派给父
类去完成，每一个层次类加载器都是如此，因此所有的加载请求都应该传送到启动类加载其中，
只有当父类加载器反馈自己无法完成这个请求的时候（在它的加载路径下没有找到所需加载的
Class），子类加载器才会尝试自己去加载。

>1. 采用双亲委派的一个好处是比如加载位于 rt.jar 包中的类 java.lang.Object，不管是哪个加载
器加载这个类，最终都是委托给顶层的启动类加载器进行加载，这样就保证了使用不同的类加载
器最终得到的都是同样一个 Object 对象。

### 3. 类加载器有哪几种？
1. 启动类加载器(Bootstrap ClassLoader)：负责加载 JAVA_HOME\lib 目录中的
2. 扩展类加载器(Extension ClassLoader)：负责加载 JAVA_HOME\lib\ext 目录中的
3. 应用程序类加载器(Application ClassLoader)：负责加载用户路径（classpath）上的类库