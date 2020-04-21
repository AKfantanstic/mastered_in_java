详细了解MySql索引相关(日常用的多，很重要)  

InnoDB引擎支持两种索引,一种是B+树索引，另一个是哈希索引。  

InnoDB存储引擎支持的哈希索引是自适应的，INNoDb存储引擎会根据表的使用情况自动为表生成哈希索引
，不能人为干预是否在一张表中生成哈希索引。  

#### mysql默认引擎为innodb，innodb默认使用行锁，而行锁是基于索引的，因此要想加上行锁，在加锁时必须命中索引，否则将使用表锁

1. Where子句过滤指定的是行而不是分组，事实上，Where没有分组的概念。那么不能用where用什么呢？
答案是Having子句。目前为止所学过的所有类型的where子句都可以用having来替代
having和where的区别：where在数据分组前对行进行过滤，having在数据分组后进行过滤

2. Union会从查询结果集中自动去除重复行，这是union的默认行为，如果需要可以用union all
来返回所有匹配的行而不进行去重。
union与where：union all为union的一种形式，如果确实需要每个条件的匹配行全部出现(包括重复行)
，则必须使用union all而不是where
在用union组合查询时，只能使用一条order by子句，它必须出现在最后一条select语句之后。
对于结果集，不存在用一种方式排序一部分，然后用另一部分排序另一部分的情况，
因此不允许使用多条order by子句。 因为union只是将所有结果集合成一个结果集，自然而然无论
有多少个union连接，都只能有一个order by子句来排序
利用union，可以把多条查询的结果作为一个结果集返回，这个结果集可以包含重复也可以不包含重复

3. 按指定顺序排序：
   SELECT
   	*
   FROM
   	uc_user_identifier
   WHERE
   	uc_user_id = 4
   ORDER BY
   	FIELD(
   		identifier_type,
   		"EMAIL",
   		"MOBILE"
   	)
   	
4. Mysql5.6升级到5.7出现groupBY的问题
   
   select @@GLOBAL.sql_mode;
   select @@SESSION.sql_mode;
   
   将结果中 ONLY_FULL_GROUP_BY去掉并保存
   解决。