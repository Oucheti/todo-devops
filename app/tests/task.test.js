const request = require("supertest");

const app = require("../src/app");

describe("TODO API", () => {

  test("GET / doit retourner le statut de l'application", async () => {

    const response = await request(app)
      .get("/");

    expect(response.statusCode).toBe(200);

    expect(response.body).toHaveProperty(
      "message",
      "TODO DevOps API"
    );
  });


  test("GET /route-inexistante doit retourner 404", async () => {

    const response = await request(app)
      .get("/route-inexistante");

    expect(response.statusCode).toBe(404);

  });


  test("POST /api/tasks sans titre doit retourner 400", async () => {

    const response = await request(app)
      .post("/api/tasks")
      .send({
        description: "Une tâche sans titre"
      });

    expect(response.statusCode).toBe(400);

    expect(response.body).toHaveProperty(
      "error",
      "Le titre est obligatoire"
    );
  });

});