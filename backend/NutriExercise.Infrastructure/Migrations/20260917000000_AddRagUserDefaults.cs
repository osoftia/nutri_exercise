using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutriExercise.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddRagUserDefaults : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BodyZone",
                table: "ResearchDocuments",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "ResearchDocuments",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "AiInteractions",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            // Idempotent seed of the default RAG test user (Id = 1).
            migrationBuilder.Sql(
                "INSERT INTO \"Users\" (\"Id\", \"Name\", \"Email\") " +
                "VALUES (1, 'Test User', 'test@nutriexercise.local') " +
                "ON CONFLICT (\"Id\") DO UPDATE SET \"Name\" = EXCLUDED.\"Name\", \"Email\" = EXCLUDED.\"Email\";");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM \"Users\" WHERE \"Id\" = 1;");

            migrationBuilder.DropColumn(
                name: "BodyZone",
                table: "ResearchDocuments");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "ResearchDocuments");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "AiInteractions");
        }
    }
}
