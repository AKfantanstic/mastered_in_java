1. 单例模式:
(1)双重检查锁:
```
public class Singleton {

    private volatile static Singleton singleton;

    // 私有化构造方法，防止随意创建对象
    private Singleton(){}

    public static Singleton getInstance(){
        // 先判断对象是否已经实例化，没有实例化则加锁
        if (singleton == null){
            // 同步代码块方式加锁
            synchronized (Singleton.class){
                if (singleton==null){
                    singleton = new Singleton();
                }
            }
        }
        return singleton;
    }
}
```
关键字: volatile  

拓展:用 volatile 修饰的原因: singleton = new Singleton(),这句话分为3步，  
        memory = allocate()  1.在内存中为对象分配一块空间  
        ctorInstance(memory) 2. 初始化对象(我理解为实例化对象)  
        instance = memory    3.将instance指向分配的内存地址  
在编译器中 2和3是可以被重排序的，用volatile来禁止指令重排序(当声明对象的引用为volatile后，2和3的重排序在多线程环境中将被禁止),volatile 还有一个作用是保持可见性

关键字: synchronized  

2. 
