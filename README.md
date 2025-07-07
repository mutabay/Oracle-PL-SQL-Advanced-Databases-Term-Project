# **Advanced Databases Term Project with Oracle PL/SQL**

## **Overview**
This repository showcases the term project for the Advanced Databases class, where my coworker and I explored Oracle PL/SQL to design and optimize a **Car Store Management System**. The primary goal of this project was to gain hands-on experience with advanced database concepts such as:
- Query optimization
- Indexing
- Partitioning
- In-memory columnar storage
- And other advanced database features

We chose **Oracle Database** because of its comprehensive feature set, giving us full access to explore and implement complex database concepts. Once its advanced capabilities are fully appreciated, Oracle Database becomes a powerful tool for building and optimizing database systems.

> **Note:** While modeling the project, there were some inconsistencies in the schema during the initial stages. For Assignment 1, the project was modeled as a **Bike Dealer System**, which was later adapted into a **Car Store Management System** (Assignment 3). This allowed us to expand the schema with additional fields and richer data.

---

## **Project Files**
The repository contains all the SQL queries, database objects, and documentation developed throughout the project. A detailed breakdown of the project deliverables is provided below.

### **Schema**
The schema of the database can be found [here](Database%20Schema.png). It serves as the backbone of the project, defining the relationships and data structures used in the Car Store Management System.

### **Project Deliverables**
Below is a detailed table of the deliverables and their purpose:

| **Row** | **Deliverable**                | **Description**                                                                 |
|---------|--------------------------------|---------------------------------------------------------------------------------|
| 1       | [Transactions](1.Transactions.pdf)         | Explanation of the database transactions and their implementation.              |
| 2       | [Table Structures](2.Table%20Structures.pdf) | Detailed documentation of the table structures used in the project.             |
| 3       | [Table Creation](3.Table%20Creating.pdf)    | SQL scripts and DDL statements for creating the database tables.                |
| 4       | [Queries and Execution Times](4.Queries%20and%20Execution%20Times.pdf) | Execution times and analysis of various queries run on the system.              |
| 5       | [Query Plans - Specification](5.Query%20Plans.pdf) | Step-by-step explanation of query execution plans and their purpose.            |
| 6       | [Indexes - Specification](6.Indexes%20Specification.pdf) | Overview of index types and their role in improving query performance.           |
| 7       | [Indexes - Development](7.Indexes%20Development.pdf) | Implementation of indexes and comparison of execution times with and without them. |
| 8       | [Partitions - Specification](8.Partitions%20Specification.pdf) | Explanation of partitioning techniques and use cases in the project.            |
| 9       | [Partitions - Development](9.Partitions%20Development.pdf) | Implementation of partitions and performance benchmarks.                        |
| 10      | [Columnar Storage - Specification](10.Columnar%20Storage%20Specification.pdf) | Detailed overview of in-memory columnar storage and its impact on query performance. |
| 11      | [Columnar Storage - Development](11.Columnar%20Storage%20Development.pdf) | Implementation and performance comparison using columnar storage.               |
| 12      | [Summary of Improvements 1](12.Summary%20Specification.pdf) | Analysis of combining two specific improvements and their impact on performance. |
| 13      | [Summary of Improvements 2](13.Summary%20Development.pdf) | Practical implementation of two combined improvements with execution time comparisons. |

---

## **Key Features**
### **1. All Queries**
- The project contains a comprehensive list of all queries used during development in the file `All Queries.sql`.
- Detailed comments are included in the file to explain the logic and solve any complexity.

### **2. Advanced Techniques**
- **Query Optimization:** Performance tuning by analyzing execution plans, reducing query time, and applying optimizations.
- **Indexes:** Types of indexes (e.g., B-Tree, Bitmap) were implemented and compared to measure the performance improvements.
- **Partitioning:** Horizontal partitioning techniques were applied to enhance data accessibility and reduce scan times.
- **In-Memory Columnar Storage:** Explored Oracle's columnar storage for faster analytics and query execution.

### **3. Performance Analysis**
- Each optimization technique was benchmarked, and execution times were measured and compared to understand the performance gains.
- Reports and explanations for each feature are provided in the corresponding deliverables.

---
