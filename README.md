# HPC Lab

This project is a small HPC-style lab built on Azure using RHEL, Slurm, shared NFS storage, scratch space, and software environment management with Spack and Conda.

## Overview

The goal is to understand and demonstrate the core workflow of a multi-node research computing platform.

## Core Components

- Login/controller node
- Multiple compute nodes
- Shared storage
- Scratch storage
- Job scheduling with Slurm
- Environment management with Spack and Conda

## Project Phases

- Phase 1: Build the core system on Azure
- Phase 2: Introduce Lustre as a high-throughput shared storage tier

## Goals

- Deploy an HPC-style cluster on Azure
- Configure Slurm for job scheduling
- Set up shared NFS storage for data and home directories
- Provide scratch space for temporary compute workloads
- Manage software environments using Spack and Conda
- Demonstrate multi-node workload workflows
- Prepare for a future Lustre integration