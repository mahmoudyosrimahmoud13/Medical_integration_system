using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System.Data;
namespace HealthHub.Infrastructure.Implementation
{
    internal class DapperRepository : IDapperRepository
    {
        readonly string ConnectionString;
        public DapperRepository(ApplicationDataBaseContext context)
        {
            ConnectionString = context?.Database?.GetConnectionString()??"";
        }
        public IDbConnection CreateConnection()
        {
            return new SqlConnection(ConnectionString);
        }
        public void ExecuteNonQuery(string query, object? parameters = null)
        {
            using var connection = CreateConnection();
            connection.Execute(query, parameters);
        }

        public async Task ExecuteNonQueryAsync(string query, object? parameters = null)
        {
            using var connection = CreateConnection();
            await connection.ExecuteAsync(query, parameters);
        }

        public IEnumerable<IEnumerable<TEntity>> GetSetOfTables<TEntity>(string query, DynamicParameters? parameters = null) where TEntity:BaseEntity
        {
            using var connection = CreateConnection();
            using var multi = connection.QueryMultiple(query, parameters);
            while (!multi.IsConsumed)
            {
                yield return multi.Read<TEntity>();
            }
        }

        public async Task<IEnumerable<IEnumerable<TEntity>>> GetSetOfTablesAstnc<TEntity>(string query, DynamicParameters? parameters = null) where TEntity:BaseEntity
        {
            var result = new List<IEnumerable<TEntity>>();

            using var connection = CreateConnection();
            using var multi = await connection.QueryMultipleAsync(query, parameters);

            while (!multi.IsConsumed)
            {
                var rows = await multi.ReadAsync<TEntity>();
                result.Add(rows);
            }

            return result;
        }

        public IEnumerable<TEntity> GetTableData<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity
        {
            using var connection = CreateConnection();
            return connection.Query<TEntity>(query, parameters);
        }

        public async Task<IEnumerable<TEntity>> GetTableDataAsync<TEntity>(string query, DynamicParameters? parameters = null) where TEntity : BaseEntity
        {
            using var connection = CreateConnection();
            return await connection.QueryAsync<TEntity>(query, parameters);
        }

      
    }
}
