using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutriExercise.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDocumentOwnershipAndBodyZone : Migration
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
                defaultValue: 0);

            migrationBuilder.Sql(
                "UPDATE \"ResearchDocuments\" SET \"UserId\" = 1 WHERE \"UserId\" = 0;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BodyZone",
                table: "ResearchDocuments");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "ResearchDocuments");
        }
    }
}
