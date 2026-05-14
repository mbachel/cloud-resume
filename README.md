# Cloud Resume Challenge

A fully serverless resume website built on AWS, deployed via CI/CD pipelines, and written as infrastructure-as-code. Live at **[resume.bachelder.me](https://resume.bachelder.me)**.

This project is my implementation of the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) — an end-to-end cloud engineering project covering static hosting, serverless backend, infrastructure as code, automated testing, and CI/CD.

---

## Architecture

```
Browser
  │
  ├──► CloudFront (CDN + HTTPS)
  │         │
  │         └──► S3 (static site: HTML, CSS, JS)
  │
  └──► API Gateway (HTTP API)
            │
            └──► Lambda (Python) ──► DynamoDB (visitor count)
```

| Layer | Service | Purpose |
|---|---|---|
| DNS | Route 53 | Custom domain routing |
| CDN | CloudFront | HTTPS, caching, global edge delivery |
| Storage | S3 | Static asset hosting |
| Compute | Lambda | Serverless visitor counter |
| Database | DynamoDB | Persistent visitor count |
| API | API Gateway (HTTP API) | REST endpoint for Lambda |
| IaC | AWS SAM | Backend infrastructure definition |
| CI/CD | GitHub Actions | Automated test, lint, and deploy |

---

## Project Structure

```
cloud-resume/
├── .github/
│   └── workflows/
│       ├── deploy-backend.yml   # Test → deploy Lambda + DynamoDB via SAM
│       └── deploy-frontend.yml  # Lint → sync to S3 → invalidate CloudFront
├── backend/
│   ├── visitor_counter/
│   │   └── app.py               # Lambda handler (Python)
│   ├── tests/
│   │   └── test_app.py          # pytest suite (4 tests)
│   ├── template.yaml            # SAM / CloudFormation template
│   └── samconfig.toml           # SAM deployment config
├── images/                      # Favicon assets (24 size variants)
├── index.html                   # Resume page
├── styles.css                   # Light/dark theme styles
├── script.js                    # Theme toggle + visitor counter fetch
├── eslint.config.js
└── .stylelintrc.json
```

---

## How It Works

### Visitor Counter

Every page load calls a POST to the API Gateway endpoint. The Lambda function increments a DynamoDB counter using an atomic `ADD` update expression and returns the new count. The frontend displays it with a pulsing badge.

```python
# backend/visitor_counter/app.py
table.update_item(
    Key={'id': 'visitors'},
    UpdateExpression='ADD #count :inc',
    ExpressionAttributeValues={':inc': Decimal(1)},
)
```

### Frontend

Static HTML, CSS, and vanilla JavaScript. Features include:
- Persistent dark/light mode toggle
- Live visitor counter with animated badge
- Embedded AWS architecture SVG diagram as background
- Responsive layout with panel-based design and blur effects

---

## CI/CD Pipelines

### Backend (`deploy-backend.yml`)

Triggered on push to `main` when files under `backend/` change.

1. **Test** — sets up Python 3.14, installs dependencies, runs `pytest backend/ -v`
2. **Deploy** (only if tests pass) — installs `aws-sam-cli`, runs `sam deploy --no-confirm-changeset`

### Frontend (`deploy-frontend.yml`)

Triggered on push to `main`.

1. **Lint** — runs `htmlhint`, `stylelint`, and `eslint` against `index.html`, `styles.css`, and `script.js`
2. **Deploy** (only if lint passes) — syncs to S3 with `aws s3 sync`, then creates a CloudFront invalidation to bust the cache

---

## Infrastructure as Code

The entire backend is defined in [`backend/template.yaml`](backend/template.yaml) using AWS SAM:

- **DynamoDB table** — `visitor-count`, on-demand billing, partition key `id`
- **Lambda function** — Python 3.14, 10s timeout, `DynamoDBCrudPolicy` scoped to the table
- **HTTP API** — auto-created by SAM, POST `/count` route wired to Lambda

Deploying from scratch:

```bash
cd backend
sam deploy --guided
```

---

## Running Tests Locally

```bash
cd backend
pip install boto3 pytest
pytest tests/ -v
```

The test suite mocks the boto3 DynamoDB resource and covers:
- HTTP 200 response
- Correct count value in response body
- CORS header presence and value
- DynamoDB `update_item` is called

---

## Tech Stack

**Infrastructure:** AWS S3, CloudFront, Lambda, DynamoDB, API Gateway, Route 53, ACM, AWS SAM  
**Backend:** Python 3.14, boto3  
**Frontend:** HTML5, CSS3, JavaScript (vanilla)  
**CI/CD:** GitHub Actions  
**Linting:** ESLint, stylelint, htmlhint  
**Testing:** pytest, unittest.mock

---

## Deployment Requirements

GitHub Actions uses the following repository secrets:

| Secret | Used by |
|---|---|
| `AWS_ACCESS_KEY_ID` | Both pipelines |
| `AWS_SECRET_ACCESS_KEY` | Both pipelines |

The IAM user or role backing these credentials needs permissions to deploy SAM stacks (CloudFormation, Lambda, DynamoDB, IAM) and to write to S3 + invalidate CloudFront.
