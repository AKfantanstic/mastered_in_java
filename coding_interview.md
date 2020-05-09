剑指offer题解:

### 问题1: 单例模式
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

### 问题3:  
解法1: 先排序，然后遍历，如果当前值和下一个值相同，则输出  
解法2: 开O(n)空间的map或者set，然后遍历，遍历判断。set在添加相同元素时会返回一个false  
解法3: 思路:首先需要遍历数组，如果当前遍历的下标和当前数字不相等，说明需要交换了，交换之前有个前提，
那就是先判断一下当前数字和数组下标为当前数字的数字是否相等，如果相等，那我们就直接找到了一个重复的数字
```
    /**
     * 思路:首先需要遍历数组，如果当前遍历的下标和当前数字不相等，说明需要交换了，交换之前有个前提，
     * 那就是先判断一下当前数字和数组下标为当前数字的数字是否相等，如果相等，那我们就直接找到了一个重复的数字
     *
     * @param nums
     * @return
     */
    public static int findRepeatNumber(int[] nums) {
        for(int i = 0; i < nums.length; i++) {
            while(nums[i] != i) {
                if(nums[i] == nums[nums[i]]) return nums[i];
                swap(nums, i, nums[i]);
            }
        }
        return -1;
    }

public static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
```

### 问题4:
```
   /**
     * 从右上角开始找，比较target和右上角值的大小，target大就去掉
     * @param matrix
     * @param target
     * @return
     */
    public static boolean findNum(int[][] matrix, int target) {
        boolean isFind = false;

        int rows = matrix.length; // 行数
        if (rows == 0) {// 输入空的二维数组直接返回false
            return false;
        }
        int columns = matrix[0].length; // 列数

        int column = columns - 1; //这里定义右上角的坐标值，也是遍历的开始点
        int row = 0;
        while (column >= 0 && row <= rows - 1) {
            if (matrix[row][column] == target) {
                isFind = true;
                break;
            } else if (target > matrix[row][column]) {// 当前数字比目标小，去掉一行
                row++;
            } else {
                // 当前数字比目标大，去掉一列
                column--;
            }
        }
        return isFind;
    }
```

```
 /**
     * 从左下角找
     *
     * @param matrix
     * @param target
     * @return
     */
    public static boolean findNumTwo(int[][] matrix, int target) {
        int rows = matrix.length;
        boolean isFind = false;

        if (rows == 0) {
            return isFind;
        }

        int columns = matrix[0].length;

        int row = rows - 1;
        int column = 0;

        while (column <= columns-1 && row >= 0) {

            if (target==matrix[row][column]){
                isFind = true;
                break;
            }else if (target>matrix[row][column]){
                column++;
            }else{
                row--;
            }
        }
        return isFind;
    }
```

### 问题6:

```
public class Problem6 {

    private List<Integer> list = new ArrayList<>();

    static class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
        }
    }

    /**
     * 用栈辅助解决
     *
     * @param head
     * @return
     */
    public int[] reversePrint(ListNode head) {

        if (head == null) {
            return new int[]{};
        }
        java.util.Stack<Integer> stack = new Stack<>();
        while (head != null) {
            stack.push(head.val);
            head = head.next;
        }
        int size = stack.size();
        int[] arr = new int[size];
        for (int i = 0; i < size; i++) {
            arr[i] = stack.pop();
        }
        return arr;
    }

    /**
     * 用递归解决
     *
     * @return
     */
    public int[] reversePrintTwo(ListNode head) {
        reverseCurrent(head);
        int[] arr = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            arr[i] = list.get(i);
        }
        return arr;
    }

    // 将节点值以递归按倒序放入list
    // 因为递归相当于函数调用函数，函数调用函数，...，直到触发终止条件。
    // 回溯（即返回时），前面的那些函数才算“执行完毕”，才可以执行下面的 list.add(head.val)  
    void reverseCurrent(ListNode head) {
        if (head == null) {
            return;
        }
        reverseCurrent(head.next);
        list.add(head.val);
    }
}
```

### 问题9:
```
public class CQueue {

    private Stack<Integer> inStack;

    private Stack<Integer> outStack;

    public CQueue() {
        inStack = new Stack<>();
        outStack = new Stack<>();
    }

    public void appendTail(int value) {
        inStack.push(value);
    }

    public int deleteHead() {
        // 两个栈都为空，说明队列内无元素
        if (inStack.isEmpty() && outStack.isEmpty()) {
            return -1;
        }
        if (outStack.isEmpty()) {
            // outStack为空时，将inStack中所有元素都压入outStack中。
            while (!inStack.isEmpty()){
                outStack.push(inStack.pop());
            }
        }
        return outStack.pop();
    }
}
```

### 问题10: 
```
public class Problem10 {
    public static void main(String[] args) {
        System.out.println(fibonacci(45));
        System.out.println(fibonacci2(45));
        System.out.println(fibonacci3(1));
    }

    /**
     * 用递归的方式去分析问题，然后用循环来解决问题。并且从下往上算，避免计算重复的子问题
     *
     * @param n
     * @return
     */
    public static long fibonacci2(int n) {
        int[] result = new int[]{0, 1};
        if (n < 2) {
            return result[n];
        }
        int fibonacciN = 0;
        int fibonacciOne = 1;

        int fibonacciTwo = 0;

        for (int i = 2; i <= n; ++i) {
            fibonacciN = (fibonacciOne + fibonacciTwo) % 1000000007;
            fibonacciTwo = fibonacciOne;
            fibonacciOne = fibonacciN;
        }
        return fibonacciN;
    }

    /**
     * a,b,sum 来保存3项的结果
     * @param n
     * @return
     */
    public static int fibonacci3(int n) {
        int a = 0, b = 1, sum;
        for (int i = 0; i < n; i++) {
            sum = (a + b) % 1000000007;
            a = b;
            b = sum;
        }
        return a;
    }


    // 纯递归方式，这种方式的缺点是子问题被重复计算
    public static long fibonacci(long n) {
        if (n <= 0) {
            return 0;
        }
        if (n == 1) {
            return n;
        }
        return (fibonacci(n - 1) + fibonacci(n - 2)) % 1000000007;

    }
}
```

### 青蛙跳台阶:  
当青蛙要跳n级台阶时，把这个过程看成一个函数 --> f(n)。当n>2时，第一次可以选跳一级，剩下的次数为f(n-1),
如果第一次选择跳2级，剩下的次数为f(n-2),得出f(n) = f(n-1)+ f(n-2),此为斐波那契数列。  

### 变态跳台阶:  
方法1: 跳n级台阶，前n-1级台阶，每个台阶都有两种选择，跳或者不跳，第n级台阶是必跳的，这级不用选择，
所以结果是2的n-1次方 
方法2: 跳n级台阶，第一步如果跳1级，那跳法有f(n-1)种;第二步如果跳2级，跳法有f(n-2)种，
所以f(n) = f(n-1)+f(n-2)+...+f(1)
f(n-1) = f(n-2)+...+f(1)
得到 上式减去下式得到: f(n) -f(n-1) = f(n-1) --> f(n) = 2 * f(n-1)  

### 问题12: 
请设计一个函数，用来判断在一个矩阵中是否存在一条包含某字符串所有字符的路径。路径可以从矩阵中的任意一格开始，每一步可以在矩阵中向左、右、上、下移动一格。
如果一条路径经过了矩阵的某一格，那么该路径不能再次进入该格子。  

思路:
1. 将目标字符串转为字符数组，方便一个个匹配  
2. 两个for循环对矩阵每个点进行扫描  
3. 从第一个点开始递归遍历  
4. （进入DFS）判断是否越界以及匹配，递归到字符数组最后一个字符，说明完成完整的匹配 返回true  
5. 将当前遍历的点存入tmp中暂存  
6. 修改当前点的字符，标记其为被访问过  
7. （递归开始）对其四个方向的点搜索是否满足匹配  
8. 递归完成后，回溯，将修改过的点还原  
9. 返回结果  
```
public class Problem12 {
    public static void main(String[] args) {
        char[][] board = new char[][]{{'A','B','C','E'},{'S','F','C','S'},{'A','D','E','E'}};
        String word = "ABCCED";
        System.out.println(exist(board,word));
    }

    public static boolean exist(char[][] board,String word){
        char[] words = word.toCharArray();
        for (int row=0;row<board.length;row++){
            for (int col = 0;col<board[0].length;col++){
                if (dfs(board,words,row,col,0)){
                    return true;
                }
            }
        }
        return false;
    }

    public static boolean dfs(char[][] board,char[] words,int row,int col,int k){
        // 如果row 或 col越界，或者当前矩阵中字符和 第k个字符不匹配，返回false
        if (row>=board.length||row<0||col>=board[0].length||col<0|| board[row][col]!=words[k]){
            return false;
        }
        if (k==words.length-1){
            return true;
        }
        char tmp = board[row][col];
        board[row][col] = '/';
        boolean res =
                dfs(board,words,row+1,col,k+1)|| dfs(board,words,row-1,col,k+1) ||
                        dfs(board,words,row,col+1,k+1)|| dfs(board,words,row,col-1,k+1);
        board[row][col] = tmp;
        return res;
    }
}
```