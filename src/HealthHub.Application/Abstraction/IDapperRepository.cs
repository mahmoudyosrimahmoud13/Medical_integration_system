using Dapper;
using System.Data;
namespace HealthHub.Application.Abstraction
{
    public interface IDapperRepository
    {
        IDbConnection CreateConnection();
        /// <summary>
        /// Executes a SQL statement that does not return any result sets, such as an INSERT, UPDATE, or DELETE command.
        /// </summary>
        /// <remarks>Use this method to execute commands that modify data or database schema but do not
        /// return rows. If the command includes parameters, provide them using the parameters argument; otherwise, pass
        /// null.</remarks>
        /// <param name="query">The SQL statement to execute. This must be a valid command supported by the underlying database.</param>
        /// <param name="parameters">An object containing the parameters to be applied to the SQL statement, or null if the statement does not
        /// require parameters.</param>
        void ExecuteNonQuery(string query, object? parameters = null);
        /// <summary>
        /// Asynchronously executes a non-query SQL command against the database.
        /// </summary>
        /// <remarks>Use this method to execute SQL commands that do not return result sets, such as data
        /// modification statements. The command is executed asynchronously, allowing the calling thread to continue
        /// without blocking.</remarks>
        /// <param name="query">The SQL statement to execute. This should be a valid non-query command such as INSERT, UPDATE, or DELETE.
        /// Cannot be null or empty.</param>
        /// <param name="parameters">An object containing the parameters to be applied to the SQL statement, or null if the command does not
        /// require parameters.</param>
        /// <returns>A task that represents the asynchronous operation.</returns>
        Task ExecuteNonQueryAsync(string query, object? parameters = null);
        /// <summary>
        /// Executes the specified SQL query and returns a sequence of result sets, each mapped to a list of entities of type
        /// TEntity.
        /// </summary>
        /// <remarks>Each list in the returned sequence corresponds to a separate result set produced by the query. The
        /// method is typically used for queries that return multiple tables in a single execution.</remarks>
        /// <typeparam name="TEntity">The type of entity to which each row in the result sets is mapped. Must inherit from BaseEntity.</typeparam>
        /// <param name="query">The SQL query to execute. The query should be structured to return multiple result sets if multiple tables are
        /// expected.</param>
        /// <param name="parameters">The parameters to pass to the SQL query, or null if no parameters are required.</param>
        /// <returns>An enumerable collection of lists, where each list contains entities of type TEntity representing a result set from
        /// the query. The collection is empty if the query returns no result sets.</returns>
        IEnumerable<IEnumerable<TEntity>> GetSetOfTables<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity;
        /// <summary>
        /// Asynchronously executes the specified query and returns a collection of result sets, each containing
        /// entities of type TEntity.
        /// </summary>
        /// <typeparam name="TEntity">The type of entity to map the query results to. Must inherit from BaseEntity.</typeparam>
        /// <param name="query">The SQL query to execute. Must be a valid query that returns one or more result sets compatible with
        /// TEntity.</param>
        /// <param name="parameters">The parameters to use with the query, or null to execute the query without parameters.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains a collection of result sets,
        /// where each result set is an enumerable of TEntity instances.</returns>
        Task<IEnumerable<IEnumerable<TEntity>>> GetSetOfTablesAstnc<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity;
        /// <summary>
        /// Executes the specified SQL query and returns a collection of entities mapped to the specified type.
        /// </summary>
        /// <typeparam name="TEntity">The type of entity to map the query results to. Must inherit from BaseEntity.</typeparam>
        /// <param name="query">The SQL query to execute against the database. The query should select columns that can be mapped to the
        /// properties of TEntity.</param>
        /// <param name="parameters">The parameters to use with the SQL query. Can be null if the query does not require parameters.</param>
        /// <returns>An enumerable collection of entities of type TEntity representing the query results. The collection is empty
        /// if no records are found.</returns>
        IEnumerable<TEntity> GetTableData<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity;
       /// <summary>
       /// Asynchronously retrieves a collection of entities from the database based on the specified SQL query and
       /// parameters.
       /// </summary>
       /// <remarks>The method executes the provided SQL query and maps the result set to instances of
       /// TEntity. The caller is responsible for ensuring that the query and parameters are valid and that the result
       /// set can be mapped to TEntity.</remarks>
       /// <typeparam name="TEntity">The type of entity to map the query results to. Must inherit from BaseEntity.</typeparam>
       /// <param name="query">The SQL query string used to select data from the database. Must be a valid SELECT statement.</param>
       /// <param name="parameters">The parameters to be applied to the SQL query. Can be null if the query does not require parameters.</param>
       /// <returns>A task that represents the asynchronous operation. The task result contains an enumerable collection of
       /// entities of type TEntity returned by the query.</returns>
        Task<IEnumerable<TEntity>> GetTableDataAsync<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity;
    }
}
