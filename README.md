# Panhandler

Panhandler is a collection of AI agents that operate based on someone putting money in the pan. It will then take a git repository and build a development plan for it, estimating the cost involved along the way (the cost being the openrouter token cost). Maybe we'll add a small service fee if it's running on our servers.

## Methodologies

The panhandler will focus predominantly on the planning and cost estimation of the operation. The idea is that you want to entice the user to put more money in the pan, so you can continue to do the actual work. Ideally if the user puts in a repo with a very small scope, you can complete the work very quickly and they will either give you a new repo or expand the scope even further. We want to ensure repeat custom so we shouldn't do anything that might decieve the user into thinking that we're doing more work than we are or that we're trying to extract more money than we're actually doing.

The essential architecture of the panhandler will be a pubsub system that will transform the repository into an ever branching tree of operations. When a new project is created, a planning event will be triggered. This will then be processed by the planner agent. The planner agent will then create a PLAN.md file that will be used to guide the development of the project. This plan will be created using a basic structure that will allow for future agents to rely on that structure to keep operational.

## Order of Operations

- User adds a new project
- User puts money in the pan (to start it will be an openrouter key to avoid handling payments)
- Planning event is triggered
- Planner agent creates a structured PLAN.md file
- Estimator agent estimates the cost of the plan

## Plan Structure

The structured plan will include the following:

- A high level "Project Overview" section that will include the vision, the scope, and the expected deliverables.
- A "Plan" section that will include the steps to complete the project.
    - The plan will be broken down into a series of phases.
    - Each phase will be broken down into a macro step.
    - The high level plan, phases and macro steps will be the sole responsibility of the planner agent.
    - When the planning agent submits the plan, each macro step will have a new event published to the pubsub system.
    - The plan expander agent will take the macro step and expand it into a list of smaller steps achievable by the developer agent. Each micro step should be atomic and as minimal in scope as possible. The plan expander agent will be be able to generate any number of micro steps from a macro step. And so must lean on producing more steps rather than overcomplicating any one step. It will also be responsible for generating an order of operations, can steps be run in parallel or do they need to be run in sequence? I want to see a tree graph of the operations and the dependencies between them.
        - The cost estimator agent will take a each macro step with the tree of micro steps and estimate the cost of the macro step.
        - The timeline agent will take a each macro step with the tree of micro steps and estimate the time to complete the macro step.
        - The risk agent will take a each macro step with the tree of micro steps and estimate the risks associated with the macro step.
        - The adjudicator agent will take the decisions of the cost estimator, timeline agent, and risk agent and decide if the macro step is worth pursuing or requires further investigation. If the macro step is worth pursuing, the developer agent will be triggered to complete the micro steps via the decision tree created by the plan expander agent. This will spin up a number of developer agents to complete the micro steps in parallel albeit some steps may be dependent on other steps.
            - The developer agent will take a micro step and complete it.
            - The quality agent will take a micro step and assess the quality of the work.
            - Every agent will be constantly emiting events to the pubsub system. This will be the central brain of the panhandler system. New agents will be triggered by events from the pubsub system. And some events may cancel the operation of running agents or force them to restart.

## Agents

- Planner: This agent will take a git repository and build a development plan for it. Focus around taking a tree of the files and the README.md and then building a PLAN.md file that will be used to guide the development of the project. This plan will be created using a basic structure that will allow for future agents to rely on that structure to keep operational.

- Estimator: This agent will take the PLAN.md file and estimate the cost of a single step in the plan. This can be spun up in parralel to assess all points in the plan concurrently. As the steps are completed, we can use the data to re-estimate the cost of the remaining steps. This data can eventually be used to fine-tune a new estimation model.

- Plan expander: This agent will take a macro step in the plan and expand it into a list of smaller steps. This will be used to allow for more detailed planning and estimation.

- Developer: This agent will take a micro step from the plan expender and 