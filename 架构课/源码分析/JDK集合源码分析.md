## ArrayList

底层使用数组实现，初始容量10，而数组的长度是固定的，不能频繁的往ArrayList中塞数据，导致它频繁进行数组扩容，避免扩容时较差的性能影响了系统的运行



优点：基于数组实现十分适合随机读，并且性能较高

缺点: 基于数组实现，如果往数组中间加元素，会导致大量的元素挪一个位置，开销很大

### add()方法的源码

```java
/**
将指定元素附加到此列表的末尾
*/
public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }
```

### set()方法源码

```java
/**
用指定元素替换列表中指定位置的元素
*/
public E set(int index, E element) {
        rangeCheck(index);

        E oldValue = elementData(index);
        elementData[index] = element;
        return oldValue;
    }
```



### add(index,element)方法的源码





### get()方法的源码





### remove()方法的源码





### 扩容

ArrayList中最关键的逻辑就是如果数组填充满了后，如何进行扩容。







底层基于数组，最大的问题就是不要频繁的往里面灌入大量数据，导致频繁的数组扩容，新老数组元素拷贝，中间位置插入元素，删除元素，都会导致大量的元素移动，随机获取一个元素，get(index)操作是性能极高的，适合随机读，不适合大量频繁的写入及插入

### 源码分析总结

* remove()、add（index，element），这两个方法都会导致数组的拷贝，大量元素的挪动，基于数组做这种随机位置的插入和删除，性能真的不是太高

* add()、add(index,element),这两个方法，都可能会导致数组需要扩容，而数组的长度是固定的，要想扩容就只能重新开辟一个更大的数组，然后把原来数组中的元素全部拷贝到新数组中。默认初始大小是10个元素，如果不停往数组里塞入数据，可能会导致瞬间数组不停的扩容，影响系统的性能

* set(),get()，定位到随机的位置去替换元素，或者是获取元素，由于是基于数组来实现随机位置的定位，性能还是很高的

## LinkedList

底层基于双向链表实现。其他所有特性都是围绕着底层用双向链表来实现的所展开的，

优点：不停往linkedList里插入元素，或者往中间插入元素，都没关系，因为链表不需要像数组那样挪动大量元素，直接在链表中加节点即可，也不用考虑扩容对性能的影响。所以使用场景非常适合频繁插入

缺点：由于底层是链表，所以不太适合随机位置读取，因为需要遍历链表。而ArrayList这种底层是数组的实现就不需要遍历，直接根据内存地址，和所指定的index，直接定位到那个元素

LinkedList和ArrayList的区别，就是数组和链表的区别

使用场景：

(1)ArrayList：一般场景都是用ArrayList代表一个集合，只要不会频繁插入或者灌入大量元素导致频繁扩容后数组频繁拷贝，用来遍历或者随机查都是可以的

(2)LinkedList: 适合频繁在list中插入和删除某个元素。LinkedList可以当作队列来用

如何回答ArrayList和LinkedList的区别是什么？

答：ArrayList的源码我看过，给你讲一下，add，remove，get，set方法的一些基于数组实现的原理是什么，数组扩容，元素移动的原理是什么，优缺点是什么

LinkedList是基于双向链表实现的，可以现场画一下他的数据结构，把他的一些常见操作原理图现场画一下，指针，双向链表的数据结构，node是怎么变化的



在队列头加一个元素，获取一个元素，删除一个元素，在队列尾部加一个元素，获取一个元素，删除一个元素，在队列中间插入一个元素获取一个元素，删除一个元素

### 插入元素

add()： 默认是在双向链表的尾部插入一个元素

add(index,element): 是在队列的中间插入一个元素

addFirst()： 在队列头部插入一个元素

addLast(): 跟add方法是一样的，也是在尾部插入一个元素



对于add(index,element)的思路，是先确定index位置在前半部分还是后半部分，如果是前半部分则从头节点遍历，如果是后半部分则从尾节点遍历，找到index位置的node，然后替换元素即可。具体源码实现:

size>>1,右移一位，相当于是size/2,如果index<(size>>1)则说明要插入的位置在队列的前半部分，就会从队列头开始遍历直到找到index那个位置的node

```java
 if (index < (size >> 1)) {
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else {
// 如果index >= size / 2，说明要找的节点是在队列的后半部分
// 此时就是从队列的尾部往前遍历
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
```







### 获取头部元素

getFirst()== peek(),其实是直接返回first指针指向的那个node。这两个方法的区别：getFirst()如果是对空list调用，会抛异常；而peek()对空list调用，会返回null

### 获取尾部元素

### 获取某个位置的元素

```java
public E get(int index) {
        checkElementIndex(index);
        return node(index).item;
}
```

这个操作是ArrayList的强项，通过数组的index就可以定位元素，性能超高。

而对于LinkedList来说，get(int index)是它的弱项。如果想要获取某个随机位置的元素， 需要使用node(index)这个方法，而这个方法需要进行链表的遍历，只不过会用index和size>>1进行比较下，如果在前半部分则从头部开始遍历；如果在后半部分则从尾部开始遍历

### 删除元素

removeLast()

removeFirst() == poll()

remove(int index)





冒泡，快排，二分查找，理论上来说，一般的算法都可以通过画图来理解。包括红黑树，treeMap，hashMap底层现在也有红黑树了，都是画图，输入一些参数并通过代码运行，图不断变动，理解这个数据结构和算法的原理

## Vector和Stack

栈，有vector和stack两个实现。stack代表了一个栈这种数据结构，它是继承自vector来实现的，而vector是一种类似于ArrayList(基于数组来实现的)数据结构，stack也是基于数组来实现的



栈的特点是先进后出

### 压栈

push()方法，几乎和ArrayList的add()方法实现的源码是一样的，就是把元素放在数组按顺序排列的位置上

```java
public synchronized void addElement(E obj) {
        modCount++;
        ensureCapacityHelper(elementCount + 1);
        elementData[elementCount++] = obj;
}
```

ArrayList每次扩容是1.5倍 capacity + (capacity >> 1)=1.5 capacity

Vector每次扩容默认是2倍，默认情况下直接扩容2倍

### 出栈

pop()方法，从栈顶弹出来一个元素，先使用elementData[size -1]获取最后一个元素，返回给用户，removeElementAt(size -1)删除了最后一个元素 ，直接将elementData[size -1]=null，直接将最后一个元素设置为null即可





linkedList可以当作队列使用：

offer() == add()，在队列尾部入队

poll()，从队列头部出队

peek()，获取队列头部的元素但不出队



## HashMap

是整个 JDK 集合包源码剖析的重点

原理与流程的概述：对key进行一个hashCode()运算，计算出key的hash值，然后把hash值对数组长度取模，定位到数组的某个下标元素上；如果某两个key对应的hash值是一样的，这样就会导致他们会被放到同一个索引位置上去，也就是发生了hash冲突，在JDK8以前，是在冲突数组下标位置挂载链表来解决的，当出现大量hash冲突后，对长链表遍历找一个k-v对的性能是O(n),但如果直接根据array[index]获取到某个元素，性能是O(1),JDK8优化了一下，如果一个链表的长度超过了8，就会自动将链表转换为红黑树，红黑树的查找性能是O(logn)，性能比O(n)高。所以 JDK 8 对HashMap的数据结构是数组 + 链表 + 红黑树

红黑树特点:

1. 红黑树是二叉查找树，左小右大，根据这个规则可以快速查找某个值
2. 普通的二叉查找树有可能出现瘸子的情况，只有一条腿，不是平衡的，导致变成线性查询，查询性能变为O(n)
3. 红黑树有红色和黑色两种节点，还有其他一堆条件限制，尽可能保证树是平衡的，不会出现瘸腿的情况
4. 如果插入节点时破坏了红黑树的规则和平衡，会自动重新平衡，变色(红 -> 黑)，旋转(左旋转，右旋转)

为什么要看源码？如果看完了源码后，理解会更加深刻一些，在面试表达时，理解的深度和表出来的东西都是不一样的

### 成员变量

* static final int  DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

默认数组初始大小是16，跟ArrayList是不一样的，ArrayList的初始默认大小是10

* static final float  DEFAULT_LOAD_FACTOR = 0.75f;

默认的负载因子，如果数组里的元素达到数组大小 16 * 负载因子 0.75f，也就是12个元素时，就会进行数组扩容

* transient Node<K,V>[] table;

Node<K,V> []，这个数组就是Map里的核心数据结构数组，这个数组里装的是Node类的对象，天然可以挂载成链表，Node里面只有一个next指针

* transient int size;

存储当前hashMap中有多少个k-v对，如果size达到了capacity*负载因子，则进行数组扩容

* int threshold;

threshold = capacity * loadFactory ,当size达到threshold时，就会进行数组扩容

* final float loadFactory;

负载因子，默认是0.75f。指定的越大，则拖慢扩容速度，一般不修改

### 内部类

```java
static class Node<K,V> implements Map.Entry<K,V> {
        final int hash;
        final K key;
        V value;
        Node<K,V> next;
}
```

这是一个很关键的内部类，代表了一个k-v对，并且对象里包括了key的hash值，key，value，还有一个可以指向下一个node的next指针，也就是指向单向链表中的下一个节点，通过这个next指针可以形成一个链表

### 方法

#### Put(key,value)

```java
public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
}
```

```java
 static final int hash(Object key) {
        int h;
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }
```

对key取计算hash值，然后传入到putVal方法中。key为空的hash值返回0，不是空的key则将key的hashCode与hashCode的右移16位的结果进行异或运算，也就是key的hashcode的高16位和低16位进行异或运算，hashCode值是一个int型值。这步其实是为了后面使用hash值定位数组下标的位运算那步来准备的。



因为最后定位到数组下标的计算时，是使用key的hash值与数组capacity进行&与运算的，因为capacity是2倍扩容，并且当第一次实例化hashMap时指定了容量，容量也会被调整为2的幂次而不是输入的那个容量。这样当定位数组下标时，就不用%取模，而是把取模运算转化为&运算，位运算，位运算效率比取模效率高得多。

所以capacity最开始转化为二进制与hash值进行&运算时，所有的key都是与capacity的低16位进行与运算的，这样就导致了只有key的低16位参与了与运算，会导致hash冲突概率增加。所以这里在计算hash值时，用hashcode的低16位和高16位进行异或运算，异或的计算规则是，相等为0，不相等的为1

异或后，就把高16位和低16位的特征，同时集中到低16位去了，这样就能保证把高16位和低16位的特征同时纳入计算。这样做就能降低hash冲突的概率



put之前，刚开始 table 数组是空的，所以默认分配一个大小是16的数组，负载因子是0.75，threshold是12:

```java
if ((tab = table) == null || (n = tab.length) == 0)
   n = (tab = resize()).length;
```

通常情况下使用数组数据结构存储数据，都是使用hashCode对数组容量进行取模定位存储的数据下标，但是hashMap使用的是hash&(n-1)去定位存储的数组下标的：

```java
// i为数组下标
i=(n-1)&hash
```

然后使用tab[i]去定位数组，最开始tab[i]位置是空的，所以直接创建一个Node对象，用来代表一个k-v对，放在数组那个位置就可以了

计算过程:

n=16,n-1=15,二进制表示为1111

&运算规则，两个数都为1则为1，否则为0

15 & hash：

1111 1111 1111 1111 0000 0101 1000 0011

​									                                          &

0000 0000 0000 0000 0000 0000 0000 1111

​																			   =					

00000000000000000000000000000000011

转换为10进制为3,即为下标为3处。

数组的初始大小为2的n次方，然后后面扩容的时候，是2倍扩容，这样都是用来保证(n-1)&hash和hash%数组.length效果一样，通过位运算代替取模运算来提升性能。

### 链表处理

当两个key的hash值相同，或者是不同的hash值定位到了数组的同一个index处，此时就是出现了hash冲突，默认情况下是使用单向链表来处理：

```java
// 如果tab[i]定位到的位置是空的，则在这里直接放一个Node
if ((p = tab[i = (n - 1) & hash]) == null)
    
// 进入else说明 i 位置已经有Node了    
else
     if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
 			// 如果满足上述条件，说明是相同的key，覆盖旧的value
			// map.put(1, “张三”)
			// map.put(1, “李四”)
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
// 张三就是oldValue
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
// value是新的值，是李四
// e.value = value，也就是将数组那个位置的Node的value设置为了新的李四，这个值
                afterNodeAccess(e);
                return oldValue;
            }
// 如果位置 i 挂载的是一棵红黑树的处理逻辑
else if(p instanceof TreeNode)
    
// 说明key不一样，出现了hash冲突，并且此时还不是红黑树结构，还是一个链表结构
else{  }

// 如果当前链表的长度(binCount)，大于等于TREEIF_THRESHOLD-1,就是说如果链表的长度大于等于8的话，就需要将这个链表转换为一个红黑树结构
if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
   treeifyBin(tab, hash);
break;
```

如果在数组的同一个位置出现大量的hash冲突后，这个位置就会挂载一个很长的链表，会导致有一些get操作的时间复杂度变成O(n)，正常使用数组下标定位位置，时间复杂度为O(1)。所以JDK 8 后优化了这块逻辑，当链表长度达到8时，将这条链表转化为红黑树，在红黑树中进行get操作，时间复杂度为O(logn),性能相比链表的O(n)会得到大幅提升。

### 链表转红黑树的过程

当遍历一个链表到第7个节点时，binCount是6

当遍历到第8个节点时，binCount是7，同时挂载第9个节点时，就会发现binCount>=7，达到了临界值，也就是说，当链表节点数量超过8时，就会将链表转换为红黑树。直接把红黑树当作黑盒子来读就行了，抓大放小

```java
TreeNode<K, V> hd = null, tl = null;
do {
    TreeNode<K, V> p = replacementTreeNode(e, null);
    if (tl == null)
        hd = p;
    else {
        p.prev = tl;
        tl.next = p;
     }
     tl = p;
} while ((e = e.next) != null);
```

先将单向链表转换为TreeNode类型组成的一个双向链表，接下来再将双向链表转换为一颗红黑树。如果数组位置 i 已经是一棵红黑树了，此时这个位置再出现一个hash冲突，就应该往红黑树中插入一个节点了，红黑树是一棵平衡的二叉查找树，所以插入时可能涉及旋转和变色:

```java
e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
```

### 扩容原理

2倍扩容加rehash，让每个k-v对重新基于key的hash值重新寻址到新的数组位置

原本当前key的hash对16取模得到index=5，但是如果扩容后对32取模，可能变成index=11，位置可能会发生变化



rehash:JDK 1.7时，数组长度16扩容到32，是重新对新数组长度重新取模运算，位置不固定

JDK1.8后，优化了rehash，使用&操作来实现hash寻址算法。

数组扩容从16 -32:

n-1      0000 0000 0000 0000 0000 0000 0000 1111
hash1  1111 1111 1111 1111 0000 1111 0001 0101
&结果  0000 0000 0000 0000 0000 0000 0000 0101 = 5(index=5的位置)
扩容后，数组长度变为32，重新计算结果：
 n-1      0000 0000 0000 0000 0000 0000 0001 1111
hash1  1111 1111 1111 1111 0000 1111 0001 0101
&结果  0000 0000 0000 0000 0000 0000 0001 0101 = 21(index=21的位置)
从5变成21，规律就是每次扩容后，要么每个hash值还停留在原来的index位置，要么变成index + oldCapacity位置











如果面试官问你HashMap的底层原理：

* hash算法：为什么要高位和 低位做异或运算？
* hash寻址：为什么是hash值和数组.length-1进行与运算？
* hash冲突的机制：链表超过8个后转换成红黑树
* 扩容机制：2倍扩容后，重新寻址(rehash)，hash & (n-1)，判断二进制结果中是否多出一个bit的1，如果没多，就是还在原来位置；如果多出来了，那么就是index + oldCapacity位置。通过这个方式避免了rehash时使用取模运算性能不高











